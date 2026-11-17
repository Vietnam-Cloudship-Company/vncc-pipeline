import pytest


PDF_CONTENT = (
    b"%PDF-1.4\n"
    b"1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj\n"
    b"2 0 obj << /Type /Pages /Kids [] /Count 0 >> endobj\n"
    b"trailer << /Root 1 0 R >>\n%%EOF\n"
)


def _require_status(response, expected, method, path):
    if response.status_code != expected:
        pytest.fail(
            f"{method} {path} must return contract success HTTP {expected}; "
            f"received HTTP {response.status_code}"
        )


@pytest.fixture(scope="session")
def uploaded_file(
    api_client, response_validator, authorization_headers, test_folder_id
):
    path = "/files"
    response = api_client.post(
        f"/api/v1{path}",
        headers=authorization_headers,
        data={"folder_id": test_folder_id, "visibility": "household"},
        files={"file": ("yard-contract-test.pdf", PDF_CONTENT, "application/pdf")},
    )
    response_validator(response, "POST", path)
    _require_status(response, 201, "POST", path)
    if "etag" not in response.headers:
        pytest.fail("POST /files did not return the contract ETag header")
    try:
        metadata = response.json()
    except ValueError:
        pytest.fail("POST /files returned invalid JSON")
    if not isinstance(metadata, dict) or not isinstance(metadata.get("id"), str):
        pytest.fail("POST /files did not return a file identifier")
    return metadata


def test_upload_file(api_client, uploaded_file):
    assert uploaded_file["id"]


def test_list_files(api_client, response_validator, authorization_headers):
    path = "/files"
    response = api_client.get(
        f"/api/v1{path}",
        headers=authorization_headers,
        params={"limit": 1},
    )
    response_validator(response, "GET", path)
    _require_status(response, 200, "GET", path)


def test_read_and_update_file_metadata(
    api_client, response_validator, authorization_headers, uploaded_file
):
    file_id = uploaded_file["id"]
    path = "/files/{id}"
    url = f"/api/v1/files/{file_id}"

    current = api_client.get(url, headers=authorization_headers)
    response_validator(current, "GET", path)
    _require_status(current, 200, "GET", path)
    etag = current.headers.get("etag")
    if not etag:
        pytest.fail("GET /files/{id} did not return the contract ETag header")

    updated = api_client.patch(
        url,
        headers={**authorization_headers, "If-Match": etag},
        json={"description": "Integration contract verification"},
    )
    response_validator(updated, "PATCH", path)
    _require_status(updated, 200, "PATCH", path)


def test_download_file_content(
    api_client, response_validator, authorization_headers, uploaded_file
):
    path = "/files/{id}/content"
    url = f"/api/v1/files/{uploaded_file['id']}/content"
    response = api_client.get(
        url,
        headers=authorization_headers,
        params={"disposition": "attachment"},
    )
    response_validator(response, "GET", path)
    _require_status(response, 200, "GET", path)
    if response.content != PDF_CONTENT:
        pytest.fail("Downloaded file bytes differ from the uploaded test document")
    if response.headers.get("accept-ranges") != "bytes":
        pytest.fail("GET /files/{id}/content did not advertise byte-range support")
    if "attachment" not in response.headers.get("content-disposition", ""):
        pytest.fail("GET /files/{id}/content did not return attachment disposition")

    partial = api_client.get(
        url,
        headers={**authorization_headers, "Range": "bytes=0-9"},
        params={"disposition": "attachment"},
    )
    response_validator(partial, "GET", path)
    _require_status(partial, 206, "GET", path)
    if partial.content != PDF_CONTENT[:10]:
        pytest.fail("GET /files/{id}/content returned incorrect partial bytes")
    if partial.headers.get("content-range") != f"bytes 0-9/{len(PDF_CONTENT)}":
        pytest.fail("GET /files/{id}/content returned an invalid Content-Range")
    if partial.headers.get("accept-ranges") != "bytes":
        pytest.fail("GET /files/{id}/content did not advertise byte-range support")
    if "attachment" not in partial.headers.get("content-disposition", ""):
        pytest.fail("GET /files/{id}/content did not return attachment disposition")
