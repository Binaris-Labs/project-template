package database

import (
	"fmt"
	"time"

	"backend/internal/config"
	"backend/pkg/logger"

	_ "github.com/jackc/pgx/v5/stdlib"
	"github.com/jmoiron/sqlx"
	"go.uber.org/zap"
)

var DB *sqlx.DB

func ConnectPostgres() {
	dsn := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable timezone=Asia/Jakarta",
		config.Envs.DBHost,
		config.Envs.DBPort,
		config.Envs.DBUser,
		config.Envs.DBPass,
		config.Envs.DBName,
	)

	var err error
	DB, err = sqlx.Connect("pgx", dsn)
	if err != nil {
		logger.Log.Fatal("❌ FATAL: Cannot connect to PostgreSQL", zap.Error(err))
	}

	DB.SetMaxOpenConns(50)

	DB.SetMaxIdleConns(10)

	DB.SetConnMaxLifetime(15 * time.Minute)

	if err := DB.Ping(); err != nil {
		logger.Log.Fatal("❌ FATAL: Database is not responding to Ping", zap.Error(err))
	}

	logger.Log.Info("✅ PostgreSQL connection pool initialized successfully")
}
