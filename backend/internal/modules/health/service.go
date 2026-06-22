package health

import (
	"context"
	"errors"
)

type Service interface {
	GetHealth(ctx context.Context) (HealthStatus, error)
}

type service struct {
	repo Repository
}

func NewService(repo Repository) Service {
	return &service{repo: repo}
}

func (s *service) GetHealth(ctx context.Context) (HealthStatus, error) {
	err := s.repo.CheckDB(ctx)
	if err != nil {
		return HealthStatus{Status: "down", Message: "Database is unreachable"}, errors.New("database connection failed")
	}

	return HealthStatus{Status: "ok", Message: "All systems operational"}, nil
}
