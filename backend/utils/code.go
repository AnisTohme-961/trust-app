package utils

import (
	"math/rand"
	"time"
)

func GenerateCode(length int) string {
	rand.Seed(time.Now().UnixNano())
	code := ""
	for i := 0; i < length; i++ {
		code += string('0' + rune(rand.Intn(10)))
	}
	return code
}
