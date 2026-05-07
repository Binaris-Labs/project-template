package auth

import (
	"context"
	"strings"

	"github.com/jmoiron/sqlx"
	"github.com/williamchandra/accountant-app/pkg/logger"
	"go.uber.org/zap"
)

// Repository defines all database operations for the Auth module
type Repository interface {
	CreateUser(ctx context.Context, email, passwordHash, fullName string) error
	GetUserByEmail(ctx context.Context, email string) (*User, error)
}

type repository struct {
	db *sqlx.DB
}

// NewRepository creates a new Auth repository injection
func NewRepository(db *sqlx.DB) Repository {
	return &repository{db: db}
}

func (r *repository) CreateUser(ctx context.Context, email, passwordHash, fullName string) error {
	query := `
		INSERT INTO users (email, password_hash, full_name)
		VALUES ($1, $2, $3)
	`
	_, err := r.db.ExecContext(ctx, query, email, passwordHash, fullName)
	
	if err != nil {
		// 1. Log the exact, ugly PostgreSQL error to our internal terminal/Datadog using Zap
		logger.Log.Error("Failed to insert user into database", zap.String("email", email), zap.Error(err))

		// 2. Catch Postgres "Duplicate Key" attack (Race Condition)
		if strings.Contains(err.Error(), "duplicate key") || strings.Contains(err.Error(), "unique constraint") {
			return ErrDuplicateEmail
		}

		// 3. Fallback generic error so we don't leak DB tables to hackers
		return ErrInternalDB
	}

	return nil
}

func (r *repository) GetUserByEmail(ctx context.Context, email string) (*User, error) {
	var user User
	// We only select the specific fields we actually need.
	query := `SELECT id, email, password_hash, full_name, is_active FROM users WHERE email = $1`
	
	err := r.db.GetContext(ctx, &user, query, email)
	if err != nil {
		return nil, ErrInvalidCredentials
	}
	return &user, nil
}
