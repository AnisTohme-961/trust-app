package services

import (
	"fmt"
	"os"

	"github.com/twilio/twilio-go"
	openapi "github.com/twilio/twilio-go/rest/api/v2010"
)

// For Later

func SendSMS(to string, code string) error {
	client := twilio.NewRestClientWithParams(twilio.ClientParams{
		Username: os.Getenv("TWILIO_SID"),
		Password: os.Getenv("TWILIO_AUTH_TOKEN"),
	})

	from := os.Getenv("TWILIO_PHONE_NUMBER")
	body := fmt.Sprintf("Your egoty reset code is: %s", code)

	params := &openapi.CreateMessageParams{}
	params.SetTo(to)
	params.SetFrom(from)
	params.SetBody(body)

	_, err := client.Api.CreateMessage(params)
	return err
}
