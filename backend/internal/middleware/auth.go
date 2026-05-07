package middleware

import (
	"strings"

	"github.com/golang-jwt/jwt/v5"
	"github.com/labstack/echo/v4"
	"github.com/williamchandra/accountant-app/internal/config"
	"github.com/williamchandra/accountant-app/pkg/respond"
)

// JWTProtected serves as the global security gatekeeper.
func JWTProtected(next echo.HandlerFunc) echo.HandlerFunc {
	return func(c echo.Context) error {
		userID, err := extractAndVerifyToken(c)
		if err != nil {
			return respond.Unauthorized(c, err.Error())
		}
		c.Set("user_id", userID)
		return next(c)
	}
}

// extractAndVerifyToken adalah tukang bedah token murni (bebas dari logika routing)
func extractAndVerifyToken(c echo.Context) (string, error) {
	authHeader := c.Request().Header.Get("Authorization")
	if authHeader == "" {
		return "", echo.NewHTTPError(401, "Missing Authorization Header")
	}

	parts := strings.Split(authHeader, " ")
	if len(parts) != 2 || parts[0] != "Bearer" {
		return "", echo.NewHTTPError(401, "Invalid Authorization format. Expected: 'Bearer <token>'")
	}

	token, err := jwt.Parse(parts[1], func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, echo.ErrUnauthorized
		}
		return []byte(config.Envs.JWTSecret), nil
	})

	if err != nil || !token.Valid {
		return "", echo.NewHTTPError(401, "Invalid or expired token")
	}

	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		return "", echo.NewHTTPError(401, "Failed to parse identity claims")
	}

	userID, ok := claims["user_id"].(string)
	if !ok || userID == "" {
		return "", echo.NewHTTPError(401, "Token missing required user_id payload")
	}

	return userID, nil
}
