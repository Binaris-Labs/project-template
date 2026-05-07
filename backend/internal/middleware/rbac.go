package middleware

import (
	"database/sql"
	"net/http"

	"github.com/jmoiron/sqlx"
	"github.com/labstack/echo/v4"
	"github.com/williamchandra/accountant-app/pkg/logger"
	"go.uber.org/zap"
)

// RequireWorkspaceRole establishes a high-performance authorization perimeter.
// This fully prevents the Multi-Tenant IDOR vulnerability by ensuring the User mathematically possesses the correct Role.
func RequireWorkspaceRole(db *sqlx.DB, allowedRoles ...string) echo.MiddlewareFunc {
	return func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			
			// 1. Extract context (Guaranteed to be present because JWTProtected ran before this)
			userID, ok := c.Get("user_id").(string)
			if !ok || userID == "" {
				return c.JSON(http.StatusUnauthorized, map[string]interface{}{
					"success": false,
					"message": "Missing or invalid token identity",
				})
			}

			workspaceID := c.Request().Header.Get("X-Workspace-Id")
			if workspaceID == "" {
				return c.JSON(http.StatusBadRequest, map[string]interface{}{
					"success": false,
					"message": "Missing X-Workspace-Id header context",
				})
			}

			// 2. Fast Authorization Database Hit
			var userRole string
			query := `SELECT role FROM workspace_members WHERE user_id = $1 AND workspace_id = $2`
			err := db.GetContext(c.Request().Context(), &userRole, query, userID, workspaceID)
			
			if err != nil {
				if err == sql.ErrNoRows {
					// Hacker identified: They tried to enter a workspace where they are not a member!
					return c.JSON(http.StatusForbidden, map[string]interface{}{
						"success": false,
						"message": "Access Denied: You do not belong to this Workspace. Incident reported.",
					})
				}
				logger.Log.Error("RBAC Database failure", zap.Error(err))
				return c.JSON(http.StatusInternalServerError, map[string]interface{}{
					"success": false,
					"message": "RBAC Authorization Engine failed",
				})
			}

			// 3. Verify exactly if their Role is part of the Required roles
			hasAccess := false
			for _, allowed := range allowedRoles {
				if userRole == allowed {
					hasAccess = true
					break
				}
			}

			if !hasAccess {
				// E.g., User is 'VIEWER', but route demands 'OWNER' or 'ADMIN'
				return c.JSON(http.StatusForbidden, map[string]interface{}{
					"success": false,
					"message": "Access Denied: Your required role is (" + userRole + "). You lack permissions for this action.",
				})
			}

			// 4. Perimeter is theoretically secure. Pass control down the Application Chain!
			return next(c)
		}
	}
}
