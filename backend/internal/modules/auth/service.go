package auth

import (
	"context"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/williamchandra/accountant-app/internal/config"
	"github.com/williamchandra/accountant-app/pkg/logger"
	"go.uber.org/zap"
	"golang.org/x/crypto/bcrypt"
)

// Service defines the Business Logic for the Auth module
type Service interface {
	Register(ctx context.Context, req RegisterRequest) error
	Login(ctx context.Context, req LoginRequest) (*TokenResponse, error)
}

type service struct {
	repo Repository
}

// NewService creates a new Auth service injection
func NewService(repo Repository) Service {
	return &service{repo: repo}
}

func (s *service) Register(ctx context.Context, req RegisterRequest) error {
	// 1. Business Logic: Check if the user already exists to prevent duplicate data errors
	_, err := s.repo.GetUserByEmail(ctx, req.Email)
	if err == nil {
		return ErrDuplicateEmail
	}

	// 2. Encryption: Hash the password using Bcrypt with default cost (10)
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return ErrHashingPassword
	}

	// 3. Database Execution: Pass the hashed password to the Repository
	err = s.repo.CreateUser(ctx, req.Email, string(hashedPassword), req.FullName)
	if err == nil {
		logger.Log.Info("New user registered successfully", zap.String("email", req.Email))
	}
	return err
}

func (s *service) Login(ctx context.Context, req LoginRequest) (*TokenResponse, error) {
	// 1. Verify Identity: Get user from the DB
	user, err := s.repo.GetUserByEmail(ctx, req.Email)
	if err != nil {
		logger.Log.Warn("Failed login attempt - user not found", zap.String("email", req.Email))
		return nil, ErrInvalidCredentials
	}

	// 2. Security Check: Physically compare the Bcrypt hash against the plain text password guess
	err = bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password))
	if err != nil {
		logger.Log.Warn("Failed login attempt - wrong password", zap.String("email", req.Email), zap.String("user_id", user.ID.String()))
		return nil, ErrInvalidCredentials
	}

	// 3. Business Rule: Check if the user account is active
	if !user.IsActive {
		logger.Log.Warn("Failed login attempt - account deactivated", zap.String("email", req.Email), zap.String("user_id", user.ID.String()))
		return nil, ErrAccountDeactivated
	}

	// 4. Token Generation: Create a standard JWT
	jwtSecret := []byte(config.Envs.JWTSecret)
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id": user.ID.String(),
		"exp":     time.Now().Add(time.Hour * 72).Unix(), // Token expires in 3 days
	})

	tokenString, err := token.SignedString(jwtSecret)
	if err != nil {
		return nil, ErrTokenGeneration
	}

	// Successfully return the JWT token and the User's details (excluding password)
	logger.Log.Info("User logged in successfully", zap.String("email", user.Email), zap.String("user_id", user.ID.String()))
	return &TokenResponse{
		Token: tokenString,
		User:  *user,
	}, nil
}
