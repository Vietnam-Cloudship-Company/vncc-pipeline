package httpapi

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestHealthAndReadiness(t *testing.T) {
	router := NewRouter()
	tests := []struct {
		path       string
		statusCode int
	}{
		{path: "/healthz", statusCode: http.StatusOK},
		{path: "/readyz", statusCode: http.StatusServiceUnavailable},
	}

	for _, test := range tests {
		t.Run(test.path, func(t *testing.T) {
			request := httptest.NewRequest(http.MethodGet, test.path, nil)
			response := httptest.NewRecorder()
			router.ServeHTTP(response, request)

			if response.Code != test.statusCode {
				t.Fatalf("status = %d, want %d", response.Code, test.statusCode)
			}
			if response.Header().Get("X-Request-ID") == "" {
				t.Fatal("X-Request-ID header is empty")
			}
		})
	}
}

func TestFileOperationsReturnExplicitNotImplementedErrors(t *testing.T) {
	router := NewRouter()
	tests := []struct {
		method string
		path   string
	}{
		{method: http.MethodPost, path: "/api/v1/files"},
		{method: http.MethodGet, path: "/api/v1/files"},
		{method: http.MethodGet, path: "/api/v1/files/file-1"},
		{method: http.MethodPatch, path: "/api/v1/files/file-1"},
		{method: http.MethodGet, path: "/api/v1/files/file-1/content"},
	}

	for _, test := range tests {
		t.Run(test.method+" "+test.path, func(t *testing.T) {
			request := httptest.NewRequest(test.method, test.path, nil)
			request.Header.Set("X-Request-ID", "test-request-1")
			response := httptest.NewRecorder()
			router.ServeHTTP(response, request)

			if response.Code != http.StatusNotImplemented {
				t.Fatalf("status = %d, want %d", response.Code, http.StatusNotImplemented)
			}

			var envelope ErrorEnvelope
			if err := json.Unmarshal(response.Body.Bytes(), &envelope); err != nil {
				t.Fatalf("decode error response: %v", err)
			}
			if envelope.Error.Code != "not_implemented" {
				t.Fatalf("error code = %q, want %q", envelope.Error.Code, "not_implemented")
			}
			if envelope.Error.RequestID != "test-request-1" {
				t.Fatalf("request_id = %q, want %q", envelope.Error.RequestID, "test-request-1")
			}
		})
	}
}
