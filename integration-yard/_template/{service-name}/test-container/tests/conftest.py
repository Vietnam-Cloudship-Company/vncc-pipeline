import os
from pathlib import Path

import pytest
import yaml
from openapi_spec_validator import validate


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
def api_base_url():
    value = os.environ.get("API_BASE_URL", "").rstrip("/")
    if not value:
        raise RuntimeError("Set API_BASE_URL to the service's Compose DNS URL")
    if "localhost" in value or "127.0.0.1" in value:
        raise ValueError("API_BASE_URL must use the service's Compose DNS name")
    return value
