package auth

import "errors"

// --------------------------------------------------------------------------
// SENTINEL ERRORS (Domain-Specific Constants)
// --------------------------------------------------------------------------
// These variables act as identical standard flags that the whole app can share.
// Instead of writing matching raw text strings, the Handler can interrogate the 
// exact "Type" of error and map it to an HTTP 400 or 500.

var (
	ErrDuplicateEmail     = errors.New("email is already registered")
	ErrInternalDB         = errors.New("internal database error occurred")
	ErrInvalidCredentials = errors.New("invalid credentials")
	ErrAccountDeactivated = errors.New("your account has been deactivated")
	ErrHashingPassword    = errors.New("failed to secure password")
	ErrTokenGeneration    = errors.New("failed to generate authentication token")
)
