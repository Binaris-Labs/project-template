package main

import (
	"github.com/williamchandra/accountant-app/internal/app"
	"github.com/williamchandra/accountant-app/pkg/logger"
)

func main() {
	// 1. Initialize the Application
	server := app.NewApp()

	// 2. Ensure logs are flushed to disk before the server turns off
	defer logger.Close()

	// 3. Start the Engine and block the main thread
	server.Run()
}
