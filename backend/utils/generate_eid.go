package utils

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"time"
)

func GenerateEID() (string, error) {
	client := &http.Client{Timeout: 5 * time.Second}

	resp, err := client.Get("http://64.227.167.28:9000/api/v1/neweid")
	if err != nil {
		fmt.Println("HTTP request error:", err)
		return "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		fmt.Println("API returned non-200 status:", resp.StatusCode)
		return "", errors.New("failed to fetch EID from API")
	}

	var result struct {
		NewEID string `json:"newEID"` // <- use newEID key
	}

	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		fmt.Println("Error decoding JSON:", err)
		return "", err
	}

	fmt.Println("Generated EID from API:", result.NewEID)

	if len(result.NewEID) != 10 {
		fmt.Println("Invalid EID length:", len(result.NewEID))
		return "", errors.New("invalid EID returned from API")
	}

	return result.NewEID, nil
}
