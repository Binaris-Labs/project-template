package logger

import (
	"log"

	"backend-template/internal/config"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

var Log *zap.Logger

func InitLogger() {
	var err error
	var zapConfig zap.Config

	if config.Envs.AppEnv == "production" {
		zapConfig = zap.NewProductionConfig()

		zapConfig.EncoderConfig.EncodeTime = zapcore.ISO8601TimeEncoder
	} else {
		zapConfig = zap.NewDevelopmentConfig()

		zapConfig.EncoderConfig.EncodeLevel = zapcore.CapitalColorLevelEncoder
	}

	Log, err = zapConfig.Build()
	if err != nil {
		log.Fatalf("❌ FATAL: Cannot initialize Uber Zap Logger: %v\n", err)
	}

	zap.ReplaceGlobals(Log)

	Log.Info("✅ Uber Zap Logger initialized successfully")
}

func Close() {
	if Log != nil {
		_ = Log.Sync()
	}
}
