package app

import (
	"github.com/labstack/echo/v4"
	"github.com/labstack/echo/v4/middleware"
	"go.uber.org/zap"

	"github.com/williamchandra/accountant-app/internal/config"
	"github.com/williamchandra/accountant-app/internal/modules/auth"
	"github.com/williamchandra/accountant-app/pkg/database"
	"github.com/williamchandra/accountant-app/pkg/logger"
	"github.com/williamchandra/accountant-app/pkg/respond"
	"github.com/williamchandra/accountant-app/pkg/validation"
)

// App holds the core dependencies of the application
type App struct {
	Router *echo.Echo
}

// NewApp initializes everything (Config, DB, Router) and returns a ready-to-run App object
func NewApp() *App {
	// 1. Load Configurations
	config.LoadConfig()

	// 2. Initialize Uber Zap Logger
	logger.InitLogger()

	// 3. Initialize Database
	database.ConnectPostgres()

	// 4. Initialize Echo Router
	router := echo.New()

	// 5. Validator
	router.Validator = validation.NewValidator()

	app := &App{
		Router: router,
	}

	app.setupMiddlewares()
	app.setupRoutes()

	return app
}

// Run boots up the HTTP server and blocks the main thread
func (a *App) Run() {
	port := config.Envs.AppPort

	// Use our new Zap logger!
	logger.Log.Info("🚀 Starting backend Server on port :" + port)

	err := a.Router.Start(":" + port)
	if err != nil {
		logger.Log.Fatal("❌ FATAL: Server crashed", zap.Error(err))
	}
}

// setupMiddlewares attaches global security and logging middlewares
func (a *App) setupMiddlewares() {
	a.Router.Use(middleware.RequestLogger())
	a.Router.Use(middleware.Recover())
	a.Router.Use(middleware.CORS())
}

// setupRoutes groups and attaches all Domain APIs
func (a *App) setupRoutes() {
	// Health Check
	a.Router.GET("/health", func(c echo.Context) error {
		return respond.Success(c, "Accountant Backend is completely wired up! 🚀", map[string]string{
			"version": "1.0.0",
		})
	})

	// --------------------------------------------------------------------------
	// DEPENDENCY INJECTION (Wiring up the Domains)
	// --------------------------------------------------------------------------

	// 1. Auth Domain
	authRepo := auth.NewRepository(database.DB)
	authService := auth.NewService(authRepo)
	authHandler := auth.NewHandler(authService)
	authHandler.RegisterRoutes(a.Router)

	// Add Domain groups here later (e.g., Sales, Purchasing)
	// api := a.Router.Group("/api")
}
