package middleware

import (
	"database/sql"
	"errors"
	"strings"

	"backend-template/internal/config"
	"backend-template/pkg/database"
	"backend-template/pkg/logger"
	"backend-template/pkg/respond"
	"github.com/golang-jwt/jwt/v5"
	"github.com/labstack/echo/v4"
	"go.uber.org/zap"
)

type sessionInfo struct {
	UserID   string `db:"user_id"`
	IsActive bool   `db:"is_active"`
	Role     string `db:"role"`
}

func JWTProtected(next echo.HandlerFunc) echo.HandlerFunc {
	return func(c echo.Context) error {
		userID, role, tokenString, err := extractAndVerifyToken(c)
		if err != nil {
			return respond.Unauthorized(c, err.Error())
		}
		c.Set("user_id", userID)
		c.Set("role", role)
		c.Set("token", tokenString)
		return next(c)
	}
}

func extractAndVerifyToken(c echo.Context) (userID string, role string, tokenString string, err error) {
	authHeader := c.Request().Header.Get("Authorization")
	if authHeader == "" {
		return "", "", "", echo.NewHTTPError(401, "Missing Authorization Header")
	}

	parts := strings.Split(authHeader, " ")
	if len(parts) != 2 || parts[0] != "Bearer" {
		return "", "", "", echo.NewHTTPError(401, "Invalid Authorization format. Expected: 'Bearer <token>'")
	}

	tokenString = parts[1]

	var info sessionInfo
	queryErr := database.DB.Get(&info,
		`SELECT s.user_id, u.is_active, r.name AS role
		 FROM sessions s
		 JOIN users u ON s.user_id = u.id
		 JOIN roles r ON u.role_id = r.id
		 WHERE s.token = $1`,
		tokenString,
	)
	if queryErr != nil {
		if errors.Is(queryErr, sql.ErrNoRows) {
			return "", "", "", echo.NewHTTPError(401, "Unauthorized: token not found or already logged out")
		}
		logger.Log.Error("middleware: session lookup failed", zap.Error(queryErr))
		return "", "", "", echo.NewHTTPError(500, "Internal server error during auth")
	}

	if !info.IsActive {
		_, _ = database.DB.Exec("DELETE FROM sessions WHERE token = $1", tokenString)
		return "", "", "", echo.NewHTTPError(401, "Unauthorized: account has been deactivated")
	}

	token, parseErr := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, echo.ErrUnauthorized
		}
		return []byte(config.Envs.JWTSecret), nil
	})

	if parseErr != nil || !token.Valid {
		if errors.Is(parseErr, jwt.ErrTokenExpired) {
			_, _ = database.DB.Exec("DELETE FROM sessions WHERE token = $1", tokenString)
			return "", "", "", echo.NewHTTPError(401, "Unauthorized: token expired")
		}
		return "", "", "", echo.NewHTTPError(401, "Invalid token")
	}

	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		return "", "", "", echo.NewHTTPError(401, "Failed to parse identity claims")
	}

	claimUserID, ok := claims["user_id"].(string)
	if !ok || claimUserID == "" {
		return "", "", "", echo.NewHTTPError(401, "Token missing required user_id payload")
	}

	return info.UserID, info.Role, tokenString, nil
}
