package validation

import "github.com/go-playground/validator/v10"

// CustomValidator holds the go-playground validator instance
type CustomValidator struct {
	validator *validator.Validate
}

// NewValidator initializes a new go-playground validator
func NewValidator() *CustomValidator {
	return &CustomValidator{validator: validator.New()}
}

// Validate is the required method signature for Echo's Custom Validator interface
func (cv *CustomValidator) Validate(i any) error {
	// The validator.Struct() will automatically read the `validate:"..."` tags from our Models!
	if err := cv.validator.Struct(i); err != nil {
		return err
	}

	return nil
}
