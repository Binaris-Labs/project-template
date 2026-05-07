package config

import (
	"log"
	"os"

	"github.com/joho/godotenv"
)

// AppConfig holds all the environment variables needed for the system to run
type AppConfig struct {
	AppPort string
	AppEnv  string // "development", "staging", "production"

	// Database Connection
	DBHost string
	DBPort string
	DBUser string
	DBPass string
	DBName string
	// Security
	JWTSecret string
}

// Global variable to hold the configurations so it can be accessed anywhere
var Envs AppConfig

// LoadConfig reads the .env file and populates the global Envs struct
func LoadConfig() {
	// Attempt to load .env file. If it fails, it will rely on System Environment Variables (useful for Docker/Production)
	err := godotenv.Load()
	if err != nil {
		log.Println("⚠️  Warning: No .env file found. Reading configuration from system OS environment variables instead.")
	}

	Envs = AppConfig{
		AppPort: getEnv("APP_PORT", "8080"),
		AppEnv:  getEnv("APP_ENV", "development"),
		DBHost: getEnv("DB_HOST", "localhost"),
		DBPort: getEnv("DB_PORT", "5432"),
		DBUser: getEnv("DB_USER", "postgres"),
		DBPass: getEnv("DB_PASSWORD", "secret"),
		DBName: getEnv("DB_NAME", "umkm_accountant"),

		JWTSecret: getEnv("JWT_SECRET", "super_secret_key_change_me_in_production"),
	}

	log.Println("✅ Environment configuration loaded successfully")
}

// getEnv is a simple helper function to read an environment variable or return a default value
func getEnv(key, fallback string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return fallback
}
