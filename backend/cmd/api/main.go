package main

import (
	"backend/internal/app"
	"backend/pkg/logger"
)

func main() {
	server := app.NewApp()

	defer logger.Close()

	server.Run()
}
