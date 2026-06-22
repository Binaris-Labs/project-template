package health

import (
	"context"
	"github.com/jmoiron/sqlx"
)

type Repository interface {
	CheckDB(ctx context.Context) error
}

type repository struct {
	db *sqlx.DB
}

func NewRepository(db *sqlx.DB) Repository {
	return &repository{db: db}
}

func (r *repository) CheckDB(ctx context.Context) error {
	var result int
	err := r.db.GetContext(ctx, &result, "SELECT 1")
	return err
}
