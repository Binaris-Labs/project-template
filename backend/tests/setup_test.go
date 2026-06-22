package tests

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"testing"
	"time"

	_ "github.com/jackc/pgx/v5/stdlib"
	"github.com/jmoiron/sqlx"
)

var baseURL = "http://localhost:8080"
var db *sqlx.DB

func TestMain(m *testing.M) {
	if u := os.Getenv("TEST_BASE_URL"); u != "" {
		baseURL = u
	}

	connStr := os.Getenv("TEST_DB_URL")
	if connStr == "" {
		connStr = fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
			"localhost", "5432", "postgres", "246810", "postgres")
	}

	var err error
	db, err = sqlx.Connect("pgx", connStr)
	if err != nil {
		fmt.Println("Test DB connect error:", err)
		os.Exit(1)
	}

	code := m.Run()
	os.Exit(code)
}

func clearDB() {
	// Add tables to clear before each test run if needed
	// db.Exec("TRUNCATE TABLE users CASCADE")
}

func reqObj(t *testing.T, method, path, token string, body interface{}) *http.Response {
	var buf bytes.Buffer
	if body != nil {
		json.NewEncoder(&buf).Encode(body)
	}
	req, _ := http.NewRequest(method, baseURL+path, &buf)
	req.Header.Set("Content-Type", "application/json")
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}
	client := &http.Client{Timeout: 5 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		t.Fatalf("Request failed: %v", err)
	}
	return resp
}
