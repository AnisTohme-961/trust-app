package services

import (
	"github.com/pquerna/otp/totp"
)

func GenerateTOTPSecret(email string) (string, string, error) {
	key, err := totp.Generate(totp.GenerateOpts{
		Issuer:      "Egoty",
		AccountName: email,
	})

	if err != nil {
		return "", "", err
	}
	return key.Secret(), key.URL(), nil
}

func VerifyTOTP(secret, code string) bool {
	return totp.Validate(code, secret)
}
