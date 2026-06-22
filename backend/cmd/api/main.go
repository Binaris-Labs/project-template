package main

import (
	"backend-template/internal/app"
	"backend-template/pkg/logger"
)

func main() {
	server := app.NewApp()

	defer logger.Close()

	server.Run()
}
