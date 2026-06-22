package respond

import (
	"net/http"

	"github.com/labstack/echo/v4"
)

type BaseResponse struct {
	Success bool         `json:"success"`
	Message string       `json:"message"`
	Data    interface{}  `json:"data,omitempty"`
	Meta    interface{}  `json:"meta,omitempty"`
	Error   *ErrorDetail `json:"error,omitempty"`
}

type ErrorDetail struct {
	Code    string `json:"code"`
	Message string `json:"message"`
}

type PaginationMeta struct {
	CurrentPage  int `json:"current_page"`
	Limit        int `json:"limit"`
	TotalRecords int `json:"total_records"`
	TotalPages   int `json:"total_pages"`
}

func Success(c echo.Context, message string, data interface{}) error {
	return c.JSON(http.StatusOK, BaseResponse{
		Success: true,
		Message: message,
		Data:    data,
	})
}

func PaginatedSuccess(c echo.Context, message string, data interface{}, meta PaginationMeta) error {
	return c.JSON(http.StatusOK, BaseResponse{
		Success: true,
		Message: message,
		Data:    data,
		Meta:    meta,
	})
}

func Created(c echo.Context, message string, data interface{}) error {
	return c.JSON(http.StatusCreated, BaseResponse{
		Success: true,
		Message: message,
		Data:    data,
	})
}

func BadRequest(c echo.Context, message string) error {
	return c.JSON(http.StatusBadRequest, BaseResponse{
		Success: false,
		Error: &ErrorDetail{
			Code:    "BAD_REQUEST",
			Message: message,
		},
	})
}

func Unauthorized(c echo.Context, message string) error {
	return c.JSON(http.StatusUnauthorized, BaseResponse{
		Success: false,
		Error: &ErrorDetail{
			Code:    "UNAUTHORIZED",
			Message: message,
		},
	})
}

func Forbidden(c echo.Context, message string) error {
	return c.JSON(http.StatusForbidden, BaseResponse{
		Success: false,
		Error: &ErrorDetail{
			Code:    "FORBIDDEN",
			Message: message,
		},
	})
}

func NotFound(c echo.Context, message string) error {
	return c.JSON(http.StatusNotFound, BaseResponse{
		Success: false,
		Error: &ErrorDetail{
			Code:    "NOT_FOUND",
			Message: message,
		},
	})
}

func Conflict(c echo.Context, message string) error {
	return c.JSON(http.StatusConflict, BaseResponse{
		Success: false,
		Error: &ErrorDetail{
			Code:    "CONFLICT",
			Message: message,
		},
	})
}

func InternalError(c echo.Context, message string) error {
	return c.JSON(http.StatusInternalServerError, BaseResponse{
		Success: false,
		Error: &ErrorDetail{
			Code:    "INTERNAL_ERROR",
			Message: message,
		},
	})
}
