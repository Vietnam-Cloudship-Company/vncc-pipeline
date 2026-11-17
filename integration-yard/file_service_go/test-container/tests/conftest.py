import os
import time
from pathlib import Path

import httpx
import pytest
import yaml
from jsonschema import Draft202012Validator, FormatChecker, ValidationError
from openapi_spec_validator import validate
from referencing import Registry, Resource
from referencing.jsonschema import DRAFT202012


TIMEOUT = httpx.Timeout(connect=3.0, read=15.0, write=15.0, pool=5.0)
OPENAPI_URI = "https://file-service-yard.invalid/openapi.yaml"


def _resolve_local_ref(spec, value):
    while isinstance(value, dict) and "$ref" in value:
        reference = value["$ref"]
        if not reference.startswith("#/"):
            raise ValueError(f"Only local OpenAPI references are supported: {reference}")
        target = spec
        for token in reference[2:].split("/"):
            token = token.replace("~1", "/").replace("~0", "~")
            target = target[token]
        value = target
    return value


def _validate_json_schema(spec, schema, value):
    def absolutize_local_refs(current):
        if isinstance(current, dict):
            return {
                key: (
                    OPENAPI_URI + item
                    if key == "$ref" and isinstance(item, str) and item.startswith("#/")
                    else absolutize_local_refs(item)
                )
                for key, item in current.items()
            }
        if isinstance(current, list):
            return [absolutize_local_refs(item) for item in current]
        return current

    root = dict(spec)
    root["$id"] = OPENAPI_URI
    registry = Registry().with_resource(
        OPENAPI_URI,
        Resource.from_contents(root, default_specification=DRAFT202012),
    )
    Draft202012Validator(
        absolutize_local_refs(schema),
        registry=registry,
        format_checker=FormatChecker(),
    ).validate(value)


def validate_live_response(response, spec, method, contract_path):
    path_item = _resolve_local_ref(spec, spec["paths"][contract_path])
    operation = _resolve_local_ref(spec, path_item[method.lower()])
    status_key = str(response.status_code)
    response_spec = operation.get("responses", {}).get(status_key)
    if response_spec is None:
        response_spec = operation.get("responses", {}).get("default")
    if response_spec is None:
        pytest.fail(
            f"{method.upper()} {contract_path} returned an undocumented status"
        )
    response_spec = _resolve_local_ref(spec, response_spec)

    for header_name, header_spec in response_spec.get("headers", {}).items():
        header_spec = _resolve_local_ref(spec, header_spec)
        header_value = response.headers.get(header_name)
        if header_value is None:
            if header_spec.get("required", False):
                pytest.fail(
                    f"{method.upper()} {contract_path} omitted a required response header"
                )
            continue
        schema = header_spec.get("schema")
        if schema is not None:
            try:
                _validate_json_schema(spec, schema, header_value)
            except ValidationError:
                pytest.fail(
                    f"{method.upper()} {contract_path} returned an invalid response header"
                )

    content = response_spec.get("content", {})
    if not content:
        if response.content:
            pytest.fail(
                f"{method.upper()} {contract_path} returned a body not defined by OpenAPI"
            )
        return

    actual_type = response.headers.get("content-type", "").split(";", 1)[0].strip().lower()
    media_type = next(
        (
            candidate
            for candidate in content
            if candidate.lower() == actual_type
            or (
                candidate.endswith("/*")
                and actual_type.startswith(candidate[:-1].lower())
            )
        ),
        None,
    )
    if media_type is None:
        pytest.fail(
            f"{method.upper()} {contract_path} returned an undeclared content type"
        )

    schema = content[media_type].get("schema")
    if schema is None:
        return
    if actual_type == "application/json" or actual_type.endswith("+json"):
        try:
            body = response.json()
        except ValueError:
            pytest.fail(
                f"{method.upper()} {contract_path} returned invalid JSON"
            )
    else:
        body = response.content.decode("latin-1")
    try:
        _validate_json_schema(spec, schema, body)
    except ValidationError:
        pytest.fail(
            f"{method.upper()} {contract_path} response did not match its OpenAPI schema"
        )


@pytest.fixture(scope="session")
def openapi_spec():
    spec_path = Path(os.environ["OPENAPI_SPEC"])
    with spec_path.open(encoding="utf-8") as spec_file:
        spec = yaml.safe_load(spec_file)
    if not isinstance(spec, dict):
        raise ValueError("OPENAPI_SPEC must contain an OpenAPI object")
    validate(spec)
    return spec


@pytest.fixture(scope="session")
def response_validator(openapi_spec):
    return lambda response, method, path: validate_live_response(
        response, openapi_spec, method, path
    )


@pytest.fixture(scope="session")
def api_base_url():
    value = os.environ.get("API_BASE_URL", "").rstrip("/")
    if not value:
        raise RuntimeError("API_BASE_URL must be set")
    if "localhost" in value or "127.0.0.1" in value:
        raise ValueError("API_BASE_URL must use the Compose service DNS name")
    return value


@pytest.fixture(scope="session")
def api_client(api_base_url, wait_for_service):
    with httpx.Client(base_url=api_base_url, timeout=TIMEOUT) as client:
        yield client


@pytest.fixture(scope="session")
def wait_for_service(api_base_url):
    ready_url = os.environ.get("API_READY_URL", "")
    timeout_seconds = int(os.environ.get("READY_TIMEOUT_SECONDS", "60"))
    interval_seconds = int(os.environ.get("READY_INTERVAL_SECONDS", "2"))
    if not ready_url:
        raise RuntimeError("API_READY_URL must identify an evidenced readiness endpoint")
    if "localhost" in ready_url or "127.0.0.1" in ready_url:
        raise ValueError("API_READY_URL must use the Compose service DNS name")
    if timeout_seconds < 1 or interval_seconds < 1:
        raise ValueError("Readiness timeout and interval must be positive integers")

    deadline = time.monotonic() + timeout_seconds
    last_status = None
    last_error = None
    while time.monotonic() <= deadline:
        try:
            response = httpx.get(
                ready_url,
                timeout=httpx.Timeout(connect=3.0, read=3.0, write=3.0, pool=3.0),
            )
            last_status = response.status_code
            if response.status_code == 200:
                return
        except httpx.RequestError as error:
            last_error = type(error).__name__
        time.sleep(min(interval_seconds, max(0, deadline - time.monotonic())))

    detail = f"last HTTP status {last_status}" if last_status is not None else last_error
    pytest.fail(f"Service did not become ready within {timeout_seconds}s ({detail})")


@pytest.fixture(scope="session")
def authorization_headers():
    token = os.environ.get("API_BEARER_TOKEN", "")
    if not token:
        pytest.fail(
            "Blocked prerequisite: inject API_BEARER_TOKEN through the CI secret mechanism"
        )
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture(scope="session")
def test_folder_id():
    folder_id = os.environ.get("API_TEST_FOLDER_ID", "")
    if not folder_id:
        pytest.fail(
            "Blocked prerequisite: provide an existing API_TEST_FOLDER_ID for the test household"
        )
    return folder_id
