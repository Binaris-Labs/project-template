package logger

import (
	"log"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
	"github.com/williamchandra/accountant-app/internal/config"
)

// Log is our global Uber Zap logger instance
var Log *zap.Logger

// InitLogger builds the Zap logger based on the current Environment (Development vs Production)
func InitLogger() {
	var err error
	var zapConfig zap.Config

	if config.Envs.AppEnv == "production" {
		// Production Mode: Fast, compact JSON logs. Perfect for Datadog or AWS CloudWatch.
		zapConfig = zap.NewProductionConfig()
		
		// Optional: Customize the timestamp format to be readable
		zapConfig.EncoderConfig.EncodeTime = zapcore.ISO8601TimeEncoder
	} else {
		// Development Mode: Colorful, human-readable terminal logs
		zapConfig = zap.NewDevelopmentConfig()
		zapConfig.EncoderConfig.EncodeLevel = zapcore.CapitalColorLevelEncoder
	}

	// Build the logger
	Log, err = zapConfig.Build()
	if err != nil {
		log.Fatalf("❌ FATAL: Cannot initialize Uber Zap Logger: %v\n", err)
	}

	// Replace the bulky global Go 'log' with our fast Zap logger under the hood
	zap.ReplaceGlobals(Log)

	Log.Info("✅ Uber Zap Logger initialized successfully")
}

// Close should be called when the server shuts down to flush any remaining logs
func Close() {
	if Log != nil {
		_ = Log.Sync()
	}
}
