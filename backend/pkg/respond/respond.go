package respond

import (
	"net/http"

	"github.com/labstack/echo/v4"
)

// BaseResponse is the strict template shape that EVERY SINGLE API must follow.
// By forcing this, the Frontend (Next.js/React) developers will never have to guess 
// how our JSON returns data.
type BaseResponse struct {
	Success bool        `json:"success"`
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
}

// Success returns a standardized 200 OK response
func Success(c echo.Context, message string, data interface{}) error {
	return c.JSON(http.StatusOK, BaseResponse{
		Success: true,
		Message: message,
		Data:    data,
	})
}

// Created returns a standardized 201 Created response (useful for POST requests)
func Created(c echo.Context, message string, data interface{}) error {
	return c.JSON(http.StatusCreated, BaseResponse{
		Success: true,
		Message: message,
		Data:    data,
	})
}

// BadRequest returns a standardized 400 response for user errors (validation, business logic blocks)
func BadRequest(c echo.Context, message string) error {
	return c.JSON(http.StatusBadRequest, BaseResponse{
		Success: false,
		Message: message,
		Data:    nil,
	})
}

// Unauthorized returns a standardized 401 response for failed logins or missing tokens
func Unauthorized(c echo.Context, message string) error {
	return c.JSON(http.StatusUnauthorized, BaseResponse{
		Success: false,
		Message: message,
		Data:    nil,
	})
}

// InternalError returns a standardized 500 response for deep server/database crashes
func InternalError(c echo.Context, message string) error {
	return c.JSON(http.StatusInternalServerError, BaseResponse{
		Success: false,
		Message: message,
		Data:    nil,
	})
}

// PaginationMeta standardizes pagination metadata for the client
type PaginationMeta struct {
	CurrentPage int `json:"current_page"`
	PerPage     int `json:"per_page"`
	TotalItems  int `json:"total_items"`
	TotalPages  int `json:"total_pages"`
}

// PaginatedResponse wraps a slice response with predictable pagination stats
type PaginatedResponse struct {
	Success    bool           `json:"success"`
	Message    string         `json:"message"`
	Data       interface{}    `json:"data"`
	Pagination PaginationMeta `json:"pagination"`
}

// SuccessPaginated calculates total pages and returns standard 200 list responses
func SuccessPaginated(c echo.Context, message string, data interface{}, page int, limit int, totalItems int) error {
	totalPages := (totalItems + limit - 1) / limit // Integer division ceil 
	if totalPages == 0 {
		totalPages = 1
	}

	return c.JSON(http.StatusOK, PaginatedResponse{
		Success: true,
		Message: message,
		Data:    data,
		Pagination: PaginationMeta{
			CurrentPage: page,
			PerPage:     limit,
			TotalItems:  totalItems,
			TotalPages:  totalPages,
		},
	})
}
