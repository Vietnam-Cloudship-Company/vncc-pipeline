package httpapi

import (
	"crypto/rand"
	"encoding/hex"
	"log/slog"
	"net/http"

	"github.com/gin-gonic/gin"
)

const requestIDKey = "request_id"

type APIError struct {
	Code      string `json:"code"`
	Message   string `json:"message"`
	RequestID string `json:"request_id"`
}

type ErrorEnvelope struct {
	Error APIError `json:"error"`
}

func NewRouter() *gin.Engine {
	router := gin.New()
	router.Use(gin.Recovery(), requestIDMiddleware())

	router.GET("/healthz", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})
	router.GET("/readyz", func(c *gin.Context) {
		writeError(c, http.StatusServiceUnavailable, "not_ready", "Storage dependencies are not configured.")
	})

	files := router.Group("/api/v1/files")
	files.POST("", notImplemented)
	files.GET("", notImplemented)
	files.GET("/:id", notImplemented)
	files.PATCH("/:id", notImplemented)
	files.GET("/:id/content", notImplemented)

	return router
}

func requestIDMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		requestID := c.GetHeader("X-Request-ID")
		if !validRequestID(requestID) {
			var err error
			requestID, err = newRequestID()
			if err != nil {
				slog.Error("generate request ID", "error", err)
				c.AbortWithStatusJSON(http.StatusInternalServerError, ErrorEnvelope{
					Error: APIError{
						Code:      "internal_error",
						Message:   "Unable to create a request identifier.",
						RequestID: "unavailable",
					},
				})
				return
			}
		}

		c.Set(requestIDKey, requestID)
		c.Header("X-Request-ID", requestID)
		c.Next()
	}
}

func validRequestID(value string) bool {
	if len(value) == 0 || len(value) > 128 {
		return false
	}
	for i := 0; i < len(value); i++ {
		character := value[i]
		if (character >= 'a' && character <= 'z') ||
			(character >= 'A' && character <= 'Z') ||
			(character >= '0' && character <= '9') ||
			character == '-' || character == '_' || character == '.' || character == ':' {
			continue
		}
		return false
	}
	return true
}

func newRequestID() (string, error) {
	var value [16]byte
	if _, err := rand.Read(value[:]); err != nil {
		return "", err
	}
	return hex.EncodeToString(value[:]), nil
}

func notImplemented(c *gin.Context) {
	writeError(c, http.StatusNotImplemented, "not_implemented", "This file operation is not implemented yet.")
}

func writeError(c *gin.Context, status int, code, message string) {
	requestIDValue, exists := c.Get(requestIDKey)
	requestID, ok := requestIDValue.(string)
	if !exists || !ok {
		requestID = "unavailable"
	}

	c.JSON(status, ErrorEnvelope{
		Error: APIError{
			Code:      code,
			Message:   message,
			RequestID: requestID,
		},
	})
}
