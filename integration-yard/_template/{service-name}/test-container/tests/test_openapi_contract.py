def test_openapi_document_is_valid(openapi_spec):
    assert openapi_spec.get("openapi")
    assert openapi_spec.get("paths")
