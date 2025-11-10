package controllers

import (
	"context"
	"flutter_project_backend/models"
	"flutter_project_backend/services"
	"log"
	"net/http"
	"time"

	"github.com/pquerna/otp/totp"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"

	"github.com/gin-gonic/gin"
)

type TOTPController struct {
	UserCollection *mongo.Collection
}

func (tc *TOTPController) GenerateTOTP(c *gin.Context) {
	var req struct {
		Email string `json:"email"`
	}

	if err := c.ShouldBindJSON(&req); err != nil || req.Email == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Email is required"})
		return
	}

	secret, qrUrl, err := services.GenerateTOTPSecret(req.Email)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate secret"})
		return
	}

	// ✅ Generate the current TOTP code
	code, err := totp.GenerateCode(secret, time.Now())
	if err != nil {
		log.Println("Error generating TOTP code:", err)
	} else {
		log.Println("DEBUG: Current TOTP code for", req.Email, "is", code)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err = tc.UserCollection.UpdateOne(ctx,
		bson.M{"email": req.Email},
		bson.M{"$set": bson.M{"twofa_secret": secret}},
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save secret"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"secret": secret, "qrUrl": qrUrl})
}

func (tc *TOTPController) VerifyTOTP(c *gin.Context) {
	var req struct {
		Email string `json:"email"`
		Code  string `json:"code"`
	}

	if err := c.ShouldBindJSON(&req); err != nil || req.Email == "" || req.Code == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input"})
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	var user models.User
	if err := tc.UserCollection.FindOne(ctx, bson.M{"email": req.Email}).Decode(&user); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "User not Found"})
		return
	}

	if user.TwoFASecret == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "2FA not enabled for this user"})
		return
	}

	if services.VerifyTOTP(user.TwoFASecret, req.Code) {
		c.JSON(http.StatusOK, gin.H{"verified": true})
	} else {
		c.JSON(http.StatusUnauthorized, gin.H{"verified": false})
	}
}
