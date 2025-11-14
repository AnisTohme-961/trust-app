package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type EmailCode struct {
	ID               primitive.ObjectID `bson:"_id,omitempty"` // MongoDB document ID
	Email            string             `bson:"email"`
	Code             string             `bson:"code"`
	SentAt           time.Time          `bson:"sentAt"`
	IsActive         bool               `bson:"isActive"`
	SendCodeAttempts int                `bson:"sendCodeAttempts"`
}
