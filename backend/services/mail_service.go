package services

import (
	"bytes"
	"fmt"
	"net/http"
	"net/url"
	"os"
)

// SendEmail sends an email using Mailgun API
func SendEmail(toEmail, subject, htmlContent string) error {
	apiKey := os.Getenv("MAILGUN_API_KEY")
	domain := os.Getenv("MAILGUN_DOMAIN")
	sender := os.Getenv("MAILGUN_SENDER")

	if apiKey == "" || domain == "" || sender == "" {
		return fmt.Errorf("MAILGUN_API_KEY, MAILGUN_DOMAIN, and MAILGUN_SENDER must be set in environment variables")
	}

	mailgunURL := fmt.Sprintf("https://api.mailgun.net/v3/%s/messages", domain)

	// Use url.Values for proper form encoding
	form := url.Values{}
	form.Set("from", sender)
	form.Set("to", toEmail)
	form.Set("subject", subject)
	form.Set("html", htmlContent)

	// Create POST request
	req, err := http.NewRequest("POST", mailgunURL, bytes.NewBufferString(form.Encode()))
	if err != nil {
		return fmt.Errorf("failed to create HTTP request: %w", err)
	}

	req.SetBasicAuth("api", apiKey)
	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return fmt.Errorf("failed to send request to Mailgun: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("Mailgun API returned non-2xx status: %s", resp.Status)
	}

	return nil
}
