package tests

import (
	"encoding/json"
	"testing"
)

func TestHealth_Ping(t *testing.T) {
	resp := reqObj(t, "GET", "/ping", "", nil)
	if resp.StatusCode != 200 {
		t.Fatalf("expected status 200, got %d", resp.StatusCode)
	}

	var res map[string]interface{}
	json.NewDecoder(resp.Body).Decode(&res)

	if res["success"] != true {
		t.Errorf("expected success to be true, got %v", res["success"])
	}

	message := res["message"].(string)
	if message != "Backend Template is running! 🚀" {
		t.Errorf("unexpected message: %s", message)
	}
}

func TestHealth_DBStatus(t *testing.T) {
	resp := reqObj(t, "GET", "/api/v1/health", "", nil)
	if resp.StatusCode != 200 {
		t.Fatalf("expected status 200, got %d", resp.StatusCode)
	}

	var res map[string]interface{}
	json.NewDecoder(resp.Body).Decode(&res)

	if res["success"] != true {
		t.Errorf("expected success to be true, got %v", res["success"])
	}

	data := res["data"].(map[string]interface{})
	if data["status"] != "ok" {
		t.Errorf("expected DB status ok, got %v", data["status"])
	}
}
