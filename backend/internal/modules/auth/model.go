package auth

import "github.com/google/uuid"

// User represents the global identity table in PostgreSQL
type User struct {
	ID           uuid.UUID `db:"id" json:"id"`
	Email        string    `db:"email" json:"email"`
	PasswordHash string    `db:"password_hash" json:"-"` // Prevents password from leaking to Frontend
	FullName     string    `db:"full_name" json:"full_name"`
	IsActive     bool      `db:"is_active" json:"is_active"`
}

// ----------------------------------------------------
// Data Transfer Objects (Payloads for Request/Response)
// ----------------------------------------------------

// RegisterRequest is what the Frontend sends to create a new user
type RegisterRequest struct {
	Email    string `json:"email" validate:"required,email"`
	Password string `json:"password" validate:"required,min=6"`
	FullName string `json:"full_name" validate:"required,min=2"`
}

// LoginRequest is what the Frontend sends to login
type LoginRequest struct {
	Email    string `json:"email" validate:"required,email"`
	Password string `json:"password" validate:"required,min=6"`
}

// TokenResponse is what we send back to the Frontend (containing the JWT and User Details)
type TokenResponse struct {
	Token string `json:"token"`
	User  User   `json:"user"`
}
