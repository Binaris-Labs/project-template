# ==============================================================================
# Accountant-App Backend Makefile
# A wise engineer automates repetitive commands to save mental energy.
# ==============================================================================

# Load environment variables from .env automatically
include .env
export
DB_URL=postgres://$(DB_USER):$(DB_PASSWORD)@$(DB_HOST):$(DB_PORT)/$(DB_NAME)?sslmode=disable

.PHONY: run build test clean tidy migrate-up migrate-down migrate-create

## run: Starts the Golang development server
run:
	go run cmd/api/main.go

## build: Compiles the application into a fast binary executable
build:
	go build -o bin/server cmd/api/main.go

## test: Runs all Unit and Integration tests
test:
	go test -v ./...

## clean: Removes compiled binaries
clean:
	rm -rf bin/

## tidy: Cleans up Go modules and downloads missing dependencies
tidy:
	go mod tidy

# ==============================================================================
# Database Migrations (golang-migrate)
# ==============================================================================

## migrate-up: Runs all UP database migrations
migrate-up:
	migrate -path db/migrations -database "$(DB_URL)" -verbose up

## migrate-down: Reverts all DOWN migrations (DANGEROUS: Wipes Database)
migrate-down:
	migrate -path db/migrations -database "$(DB_URL)" -verbose down -all

## migrate-create: Creates a new empty migration file (usage: make migrate-create name=add_users)
migrate-create:
	migrate create -ext sql -dir db/migrations -seq $(name)
