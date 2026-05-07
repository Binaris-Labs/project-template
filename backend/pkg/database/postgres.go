package database

import (
	"fmt"
	"time"

	// The '_' (Blank Identifier) silently registers the PostgreSQL Translator (pgx) into sqlx's brain.
	// If we didn't use '_', Go would yell at us for importing a file we never explicitly type in our code!
	_ "github.com/jackc/pgx/v5/stdlib"
	"github.com/jmoiron/sqlx"
	"github.com/williamchandra/accountant-app/internal/config"
	"github.com/williamchandra/accountant-app/pkg/logger"
	"go.uber.org/zap"
)

// DB is the global database connection pool
var DB *sqlx.DB

// ConnectPostgres initializes the database connection using the loaded environment variables
func ConnectPostgres() {
	// 1. Build the Data Source Name (DSN) connection string
	dsn := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable timezone=Asia/Jakarta",
		config.Envs.DBHost,
		config.Envs.DBPort,
		config.Envs.DBUser,
		config.Envs.DBPass,
		config.Envs.DBName,
	)

	// 2. Open the connection using the pgx driver
	var err error
	DB, err = sqlx.Connect("pgx", dsn)
	if err != nil {
		logger.Log.Fatal("❌ FATAL: Cannot connect to PostgreSQL", zap.Error(err))
	}

	// 3. CONFIGURE THE CONNECTION POOL (CRITICAL FOR DEVOPS)
	// This physically prevents the "N+1 Too Many Connections" crash we discussed earlier!
	
	// Max physical connections allowed to Postgres at the exact same time
	DB.SetMaxOpenConns(50) 
	
	// Max connections left open but sleeping (Waiting for new API traffic)
	DB.SetMaxIdleConns(10) 
	
	// Max time a connection can stay alive before being destroyed and recycled (prevents memory leaks)
	DB.SetConnMaxLifetime(15 * time.Minute)

	// 4. Verify the database is actually reachable
	if err := DB.Ping(); err != nil {
		logger.Log.Fatal("❌ FATAL: Database is not responding to Ping", zap.Error(err))
	}

	logger.Log.Info("✅ PostgreSQL connection pool initialized successfully")
}
