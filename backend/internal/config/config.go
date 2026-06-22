package config

import (
	"log"
	"os"

	"github.com/joho/godotenv"
)

type AppConfig struct {
	AppPort string
	AppEnv  string

	DBHost              string
	DBPort              string
	DBUser              string
	DBPass              string
	DBName              string
	JWTSecret           string
	CloudinaryCloudName string
	CloudinaryAPIKey    string
	CloudinaryAPISecret string
}

var Envs AppConfig

func LoadConfig() {
	err := godotenv.Load()
	if err != nil {
		log.Println("⚠️  Warning: No .env file found. Reading configuration from system OS environment variables instead.")
	}

	Envs = AppConfig{
		AppPort: getEnv("APP_PORT", "8080"),
		AppEnv:  getEnv("APP_ENV", "development"),
		DBHost:  getEnv("DB_HOST", "localhost"),
		DBPort:  getEnv("DB_PORT", "5432"),
		DBUser:  getEnv("DB_USER", "postgres"),
		DBPass:  getEnv("DB_PASSWORD", "secret"),
		DBName:  getEnv("DB_NAME", "church_admin_db"),

		JWTSecret: getEnv("JWT_SECRET", "super_secret_key_change_me_in_production"),

		CloudinaryCloudName: getEnv("CLOUDINARY_CLOUD_NAME", "your_cloud_name"),
		CloudinaryAPIKey:    getEnv("CLOUDINARY_API_KEY", "your_api_key"),
		CloudinaryAPISecret: getEnv("CLOUDINARY_API_SECRET", "your_api_secret"),
	}

	log.Println("✅ Environment configuration loaded successfully")
}

func getEnv(key, fallback string) string {
	if value, exists := os.LookupEnv(key); exists {
		return value
	}
	return fallback
}
