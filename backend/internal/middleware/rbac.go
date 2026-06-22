package middleware

import (
	"slices"

	"github.com/labstack/echo/v4"

	"backend/pkg/respond"
)

func RequireRole(allowedRoles ...string) echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {

			userRole, ok := c.Get("role").(string)
			if !ok || userRole == "" {
				return respond.Unauthorized(c, "Missing or invalid identity")
			}

			if slices.Contains(allowedRoles, userRole) {
				return next(c)
			}

			return respond.Forbidden(c, "Access Denied: You do not have permission for this action")
		}
	}
}
