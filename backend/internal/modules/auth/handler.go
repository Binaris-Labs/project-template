package auth

import (
	"errors"

	"github.com/labstack/echo/v4"
	"github.com/williamchandra/accountant-app/pkg/respond"
)

// Handler serves as the HTTP controller parsing frontend requests
type Handler struct {
	service Service
}

// NewHandler creates a new Auth handler injection
func NewHandler(service Service) *Handler {
	return &Handler{service: service}
}

// RegisterRoutes attaches the endpoints to the main Echo router
func (h *Handler) RegisterRoutes(e *echo.Echo) {
	authGroup := e.Group("/api/auth")

	authGroup.POST("/register", h.Register)
	authGroup.POST("/login", h.Login)
}

// Register handles HTTP user registration
func (h *Handler) Register(c echo.Context) error {
	var req RegisterRequest
	
	// 1. Parse JSON Payload from Frontend
	if err := c.Bind(&req); err != nil {
		return respond.BadRequest(c, "Invalid request payload")
	}

	// 2. Validate Payload
	if err := c.Validate(&req); err != nil {
		return respond.BadRequest(c, err.Error())
	}

	// 3. Call Service (The Business Engine)
	err := h.service.Register(c.Request().Context(), req)
	if err != nil {
		// Explicitly map severe server errors to HTTP 500
		if errors.Is(err, ErrInternalDB) || errors.Is(err, ErrHashingPassword) {
			return respond.InternalError(c, err.Error())
		}
		// Everything else (like Duplicate Email) is a User Typo -> HTTP 400 Bad Request
		return respond.BadRequest(c, err.Error())
	}

	// 4. Standardized JSON Response Box
	return respond.Created(c, "User registered successfully", nil)
}

// Login handles user authentication and JWT return
func (h *Handler) Login(c echo.Context) error {
	var req LoginRequest
	
	// 1. Parse JSON Payload
	if err := c.Bind(&req); err != nil {
		return respond.BadRequest(c, "Invalid request payload")
	}

	if err := c.Validate(&req); err != nil {
		return respond.BadRequest(c, err.Error())
	}

	// 2. Call Service to verify passwords and generate Token
	res, err := h.service.Login(c.Request().Context(), req)
	if err != nil {
		// Map backend explosion to 500
		if errors.Is(err, ErrInternalDB) || errors.Is(err, ErrTokenGeneration) {
			return respond.InternalError(c, err.Error())
		}
		// Invalid credentials Map to 401 Unauthorized
		return respond.Unauthorized(c, err.Error())
	}

	// 3. Return Token to Frontend
	return respond.Success(c, "Login successful", res)
}
