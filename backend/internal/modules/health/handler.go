package health

import (
	"github.com/labstack/echo/v4"
	"backend-template/pkg/respond"
	"go.uber.org/zap"
	"backend-template/pkg/logger"
)

type Handler struct {
	service Service
}

func NewHandler(service Service) *Handler {
	return &Handler{service: service}
}

func (h *Handler) RegisterRoutes(e *echo.Echo) {
	e.GET("/api/v1/health", h.GetHealth)
}

func (h *Handler) GetHealth(c echo.Context) error {
	ctx := c.Request().Context()

	status, err := h.service.GetHealth(ctx)
	if err != nil {
		logger.Log.Error("Health check failed", zap.Error(err))
		return respond.InternalError(c, status.Message)
	}

	return respond.Success(c, status.Message, status)
}
