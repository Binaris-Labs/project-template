# ==============================================================================
# Binaris Labs - Backend Template Makefile
# ==============================================================================

-include .env
export
DB_URL=postgres://$(DB_USER):$(DB_PASSWORD)@$(DB_HOST):$(DB_PORT)/$(DB_NAME)?sslmode=disable

.PHONY: run build test clean tidy migrate-up migrate-down migrate-create mock

## run: Starts the Golang development server
run:
	go run cmd/api/main.go

## build: Compiles the application into a fast binary executable
build:
	go build -o bin/server cmd/api/main.go

## mock: Generates mock files for all Repository interfaces using vektra/mockery
mock:
	@echo "==> Generating mocks..."
	rm -rf ./mocks
	~/go/bin/mockery --all --dir ./internal/modules --output ./mocks --keeptree

## test: Runs all Unit and Integration tests
test: test-unit test-integration

## test-unit: Runs only fast Unit Tests (No DB required)
test-unit:
	go test -v ./internal/...

## test-integration: Runs only slow Integration Tests (Requires running PostgreSQL)
test-integration:
	go test -v ./tests/...

## clean: Removes compiled binaries
clean:
	rm -rf bin/

## tidy: Cleans up Go modules
tidy:
	go mod tidy
	go mod verify

# ==============================================================================
# Database Migrations (using golang-migrate)
# ==============================================================================

## migrate-up: Applies all pending migrations to the database
migrate-up:
	migrate -path db/migrations -database "$(DB_URL)" -verbose up

## migrate-down: Reverts the last applied migration
migrate-down:
	migrate -path db/migrations -database "$(DB_URL)" -verbose down 1

## migrate-create name=xyz: Creates a new pair of UP and DOWN migration files
migrate-create:
	@if [ -z "$(name)" ]; then echo "Error: Please provide a name (e.g. make migrate-create name=init_schema)"; exit 1; fi
	migrate create -ext sql -dir db/migrations -seq $(name)
