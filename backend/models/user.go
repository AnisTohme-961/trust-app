package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type User struct {
	ID               primitive.ObjectID `bson:"_id,omitempty"`
	FirstName        string             `bson:"firstName"`
	LastName         string             `bson:"lastName"`
	Email            string             `bson:"email"`
	EmailCode        string             `bson:"emailCode"`
	EmailCodeSent    time.Time          `bson:"emailCodeSent"`
	Password         string             `bson:"password"` // hashed
	SponsorCode      string             `bson:"sponsorCode"`
	Gender           string             `bson:"gender"`
	Country          Country            `bson:"country"`  // ✅ Changed from string to Country
	Language         Language           `bson:"language"` // ✅ Changed from string to Language
	DateOfBirth      time.Time          `bson:"dob"`
	EID              string             `bson:"eid" json:"eid"`
	CreatedAt        time.Time          `bson:"created_at" json:"created_at"`
	FailedAttempts   int                `bson:"failedAttempts,omitempty" json:"failedAttempts"`
	LastFailedAt     time.Time          `bson:"lastFailedAt,omitempty" json:"lastFailedAt"`
	AccountLockUntil time.Time          `bson:"accountLockUntil,omitempty" json:"accountLockUntil"`
	Pin              string             `bson:"pin,omitempty" json:"pin,omitempty"`
	Pattern          string             `bson:"pattern,omitempty" json:"pattern,omitempty"`
	Phone            string             `bson:"phone,omitempty" json:"phone,omitempty"`
	TwoFASecret      string             `bson:"twofa_secret,omitempty" json:"twofa_secret,omitempty"`
}
