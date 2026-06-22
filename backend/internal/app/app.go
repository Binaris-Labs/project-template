package app

import (
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
	"go.uber.org/zap"

	"backend-template/internal/config"
	"backend-template/internal/modules/health"
	"backend-template/pkg/database"
	"backend-template/pkg/logger"
	"backend-template/pkg/respond"
	"backend-template/pkg/validation"
)

type App struct {
	Router *echo.Echo
}

func NewApp() *App {
	config.LoadConfig()

	logger.InitLogger()

	database.ConnectPostgres()

	router := echo.New()

	router.Validator = validation.NewValidator()

	app := &App{
		Router: router,
	}

	app.setupMiddlewares()
	app.setupRoutes()

	return app
}

func (a *App) Run() {
	port := config.Envs.AppPort

	logger.Log.Info("🚀 Starting backend Server on port :" + port)

	err := a.Router.Start(":" + port)
	if err != nil {
		logger.Log.Fatal("❌ FATAL: Server crashed", zap.Error(err))
	}
}

func (a *App) setupMiddlewares() {
	a.Router.Use(middleware.Logger())
	a.Router.Use(middleware.Recover())
	a.Router.Use(middleware.CORS())
}

func (a *App) setupRoutes() {
	a.Router.GET("/ping", func(c echo.Context) error {
		return respond.Success(c, "Backend Template is running! 🚀", map[string]string{
			"version": "1.0.0",
		})
	})

	healthRepo := health.NewRepository(database.DB)
	healthService := health.NewService(healthRepo)
	healthHandler := health.NewHandler(healthService)
	healthHandler.RegisterRoutes(a.Router)

	logger.Log.Info("✅ All modules wired: health")
}
