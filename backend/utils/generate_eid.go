package utils

import (
	"math/rand"
	"time"
)

func GenerateEID() string {
	rand.Seed(time.Now().UnixNano())
	eid := ""
	for i := 0; i < 10; i++ {
		eid += string('0' + rune(rand.Intn(10)))
	}
	return eid
}
