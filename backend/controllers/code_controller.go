package controllers

import (
	"context"
	"errors"
	"flutter_project_backend/models"
	"flutter_project_backend/services"
	"flutter_project_backend/utils"
	"fmt"
	"log"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type CodeController struct {
	EmailCodeCollection *mongo.Collection
	UserCollection      *mongo.Collection
}

// func CleanupExpiredCodes(collection *mongo.Collection) {
// 	ticker := time.NewTicker(24 * time.Hour) // run every 24 hours
// 	defer ticker.Stop()

// 	for {
// 		<-ticker.C
// 		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
// 		defer cancel()

// 		cutoff := time.Now().Add(-2 * time.Minute) // codes older than 2 minutes
// 		filter := bson.M{
// 			"sentAt":   bson.M{"$lt": cutoff},
// 			"isActive": true,
// 		}

// 		result, err := collection.UpdateMany(ctx, filter, bson.M{"$set": bson.M{"isActive": false}})
// 		if err != nil {
// 			log.Println("Error cleaning up expired codes:", err)
// 			continue
// 		}

// 		log.Printf("Cleanup job: %d expired codes deactivated\n", result.ModifiedCount)
// 	}
// }

// Send a verification code

func getCooldown(attempt int) time.Duration {
	switch attempt {
	case 0:
		return 0
	case 1:
		return 2 * time.Minute
	case 2:
		return 3 * time.Minute
	case 3:
		return 5 * time.Minute
	case 4:
		return 15 * time.Minute
	case 5:
		return time.Hour
	default:
		return 24 * time.Hour
	}
}

func (cc *CodeController) GetCode(c *gin.Context) {
	var req struct {
		Email string `json:"email"`
	}

	if err := c.BindJSON(&req); err != nil || req.Email == "" {
		fmt.Println("❌ INVALID REQUEST")
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	now := time.Now()
	var existing models.EmailCode
	var newCode string
	var attempts int

	fmt.Println("📩 Incoming request for email:", req.Email)

	findErr := cc.EmailCodeCollection.FindOne(ctx, bson.M{"email": req.Email}).Decode(&existing)

	if findErr == nil {
		// -----------------------------------------
		// EMAIL EXISTS
		// -----------------------------------------
		fmt.Println("🔍 Email found in DB:", existing.Email)
		fmt.Println("📊 Previous attempts:", existing.SendCodeAttempts)
		fmt.Println("⏱ Last sent at:", existing.SentAt)

		attempts = existing.SendCodeAttempts
		cooldown := getCooldown(attempts)
		elapsed := now.Sub(existing.SentAt)

		fmt.Println("⏳ Cooldown required:", cooldown)
		fmt.Println("⏱ Time elapsed:", elapsed)

		if elapsed < cooldown {
			remaining := int((cooldown - elapsed).Seconds())
			fmt.Println("🚫 Still in cooldown. Remaining:", remaining)

			c.JSON(http.StatusBadRequest, gin.H{
				"error":       "cooldown active",
				"secondsLeft": remaining,
				"attempts":    attempts,
			})
			return
		}

		// Cooldown passed → send new code
		newCode = utils.GenerateCode(6)
		attempts++

		fmt.Println("✅ Cooldown passed → Sending NEW CODE:", newCode)
		fmt.Println("📈 Incrementing attempts to:", attempts)

		opts := options.FindOneAndUpdate().SetReturnDocument(options.After)
		updateErr := cc.EmailCodeCollection.FindOneAndUpdate(
			ctx,
			bson.M{"email": req.Email},
			bson.M{
				"$set": bson.M{
					"code":     newCode,
					"sentAt":   now,
					"isActive": true,
				},
				"$inc": bson.M{"sendCodeAttempts": 1},
			},
			opts,
		).Decode(&existing)

		if updateErr != nil {
			fmt.Println("❌ FAILED updating existing code:", updateErr)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to update code"})
			return
		}

	} else if errors.Is(findErr, mongo.ErrNoDocuments) {
		// -----------------------------------------
		// FIRST TIME EMAIL
		// -----------------------------------------
		fmt.Println("✨ Email not found → creating new record")
		newCode = utils.GenerateCode(6)
		attempts = 1

		doc := models.EmailCode{
			Email:            req.Email,
			Code:             newCode,
			SentAt:           now,
			IsActive:         true,
			SendCodeAttempts: 1,
		}

		_, err := cc.EmailCodeCollection.InsertOne(ctx, doc)
		if err != nil {
			fmt.Println("❌ Insert failed:", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to insert code"})
			return
		}

		fmt.Println("✅ Inserted NEW email with code:", newCode)
		existing = doc

	} else {
		// -----------------------------------------
		// DB ERROR
		// -----------------------------------------
		fmt.Println("❌ DATABASE ERROR:", findErr)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "database error"})
		return
	}

	// -----------------------------------------
	// SEND EMAIL
	// -----------------------------------------
	fmt.Println("📧 Sending email to:", req.Email)

	if err := services.SendEmail(
		req.Email,
		"Your Verification Code",
		fmt.Sprintf("<h1>Your code is: %s</h1>", newCode),
	); err != nil {
		fmt.Println("❌ FAILED SENDING EMAIL:", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to send email"})
		return
	}

	fmt.Println("🎉 EMAIL SENT SUCCESSFULLY")
	fmt.Println("📈 Final attempts saved:", attempts)

	c.JSON(http.StatusOK, gin.H{
		"code":        newCode,
		"attempts":    attempts,
		"secondsLeft": 0,
	})
}

// func (cc *CodeController) GetCode(c *gin.Context) {
// 	var req struct {
// 		Email string `json:"email"`
// 	}

// 	if err := c.BindJSON(&req); err != nil || req.Email == "" {
// 		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
// 		return
// 	}

// 	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
// 	defer cancel()

// 	var existing models.EmailCode
// 	err := cc.EmailCodeCollection.FindOne(ctx, bson.M{"email": req.Email}).Decode(&existing)

// 	now := time.Now()

// 	// Determine cooldown duration based on attempts
// 	var waitDuration time.Duration
// 	switch existing.SendCodeAttempts {
// 	case 0:
// 		waitDuration = 0 * time.Minute
// 	case 1:
// 		waitDuration = 2 * time.Minute
// 	case 2:
// 		waitDuration = 3 * time.Minute
// 	case 3:
// 		waitDuration = 5 * time.Minute
// 	case 4:
// 		waitDuration = 15 * time.Minute
// 	case 5:
// 		waitDuration = 60 * time.Minute
// 	default:
// 		waitDuration = 24 * time.Hour
// 	}

// 	// Check cooldown
// 	if !errors.Is(err, mongo.ErrNoDocuments) {
// 		if time.Since(existing.SentAt) >= 15*time.Minute {
// 			log.Printf("⚠ Code expired after 15 minutes. Generating new one for %s", req.Email)
// 		} else {
// 			// If cooldown not finished, block resend
// 			elapsed := now.Sub(existing.SentAt)
// 			if elapsed < waitDuration {
// 				remaining := waitDuration - elapsed
// 				c.JSON(http.StatusBadRequest, gin.H{
// 					"error": fmt.Sprintf("Please wait %v before requesting another code.", remaining.Truncate(time.Second)),
// 				})
// 				return
// 			}
// 		}
// 	}

// 	// Generate a new code and increment attempts
// 	newCode := utils.GenerateCode(6)
// 	newAttempts := existing.SendCodeAttempts + 1

// 	emailDoc := bson.M{
// 		"email":            req.Email,
// 		"code":             newCode,
// 		"sentAt":           now,
// 		"isActive":         true,
// 		"sendCodeAttempts": newAttempts,
// 	}

// 	_, err = cc.EmailCodeCollection.UpdateOne(
// 		ctx,
// 		bson.M{"email": req.Email},
// 		bson.M{"$set": emailDoc},
// 		options.Update().SetUpsert(true),
// 	)
// 	if err != nil {
// 		c.JSON(http.StatusInternalServerError, gin.H{"error": "database error"})
// 		return
// 	}

// 	errMail := services.SendEmail(
// 		req.Email,
// 		"Your Verification Code",
// 		fmt.Sprintf("<h1>Your code is: %s</h1>", newCode),
// 	)
// 	if errMail != nil {
// 		log.Println("Failed to send email:", errMail)
// 		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to send email"})
// 		return
// 	}

// 	log.Printf("✅ Sent new code %s to %s (attempt #%d)\n", newCode, req.Email, newAttempts)
// 	c.JSON(http.StatusOK, gin.H{"code": newCode})
// }

// func (cc *CodeController) GetCode(c *gin.Context) {
// 	var req struct {
// 		Email string `json:"email"`
// 	}

// 	if err := c.BindJSON(&req); err != nil || req.Email == "" {
// 		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
// 		return
// 	}

// 	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
// 	defer cancel()

// 	// if cc.UserCollection != nil {
// 	// 	var existingUser bson.M
// 	// 	errUser := cc.UserCollection.FindOne(ctx, bson.M{"email": req.Email}).Decode(&existingUser)
// 	// 	if errUser == nil {
// 	// 		c.JSON(http.StatusBadRequest, gin.H{"error": "Email already registered. Please log in instead."})
// 	// 		return
// 	// 	}
// 	// }

// 	var existing models.EmailCode
// 	err := cc.EmailCodeCollection.FindOne(ctx, bson.M{"email": req.Email, "isActive": true}).Decode(&existing)
// 	if err == nil && time.Since(existing.SentAt) < 2*time.Minute {
// 		log.Println("Resending existing code:", existing.Code)
// 		c.JSON(http.StatusOK, gin.H{"code": existing.Code})
// 		return
// 	}

// 	newCode := utils.GenerateCode(6)
// 	emailDoc := models.EmailCode{
// 		Email:    req.Email,
// 		Code:     newCode,
// 		SentAt:   time.Now(),
// 		IsActive: true,
// 	}

// 	_, err = cc.EmailCodeCollection.UpdateOne(
// 		ctx,
// 		bson.M{"email": req.Email},
// 		bson.M{"$set": emailDoc},
// 		options.Update().SetUpsert(true),
// 	)
// 	if err != nil {
// 		c.JSON(http.StatusInternalServerError, gin.H{"error": "database error"})
// 		return
// 	}

// 	errMail := services.SendEmail(
// 		req.Email,
// 		"Your Verification Code",
// 		fmt.Sprintf("<h1>Your code is: %s</h1>", newCode),
// 	)
// 	if errMail != nil {
// 		log.Println("Failed to send email:", errMail)
// 		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to send email"})
// 		return
// 	}

// 	log.Println("Generated new code:", newCode)
// 	c.JSON(http.StatusOK, gin.H{"code": newCode})
// }

// func (cc *CodeController) VerifyCode(c *gin.Context) {
// 	var req struct {
// 		Email string `json:"email"`
// 		Code  string `json:"code"`
// 	}

// 	if err := c.BindJSON(&req); err != nil || req.Email == "" || req.Code == "" {
// 		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
// 		return
// 	}

// 	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
// 	defer cancel()

// 	var existing models.EmailCode
// 	err := cc.EmailCodeCollection.FindOne(ctx, bson.M{"email": req.Email, "isActive": true}).Decode(&existing)
// 	if err != nil {
// 		c.JSON(http.StatusOK, gin.H{"valid": false, "error": "no active code found"})
// 		return
// 	}

// 	// Expired code
// 	if time.Since(existing.SentAt) > 2*time.Minute {
// 		// delete immediately
// 		_, _ = cc.EmailCodeCollection.DeleteOne(ctx, bson.M{"_id": existing.ID})
// 		c.JSON(http.StatusOK, gin.H{"valid": false, "error": "code expired"})
// 		return
// 	}

// 	// Correct code
// 	if req.Code == existing.Code {
// 		// deactivate after use (or you could delete instead)
// 		_, _ = cc.EmailCodeCollection.UpdateOne(ctx,
// 			bson.M{"_id": existing.ID},
// 			bson.M{"$set": bson.M{"isActive": false}},
// 		)
// 		c.JSON(http.StatusOK, gin.H{"valid": true})
// 		return
// 	}

// 	// Incorrect code
// 	c.JSON(http.StatusOK, gin.H{"valid": false})
// }

func (cc *CodeController) VerifyCode(c *gin.Context) {
	var req struct {
		Email string `json:"email"`
		Code  string `json:"code"`
	}

	if err := c.BindJSON(&req); err != nil || req.Email == "" || req.Code == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	var existing models.EmailCode
	err := cc.EmailCodeCollection.FindOne(ctx, bson.M{
		"email":    req.Email,
		"isActive": true,
	}).Decode(&existing)

	if err != nil {
		c.JSON(http.StatusOK, gin.H{"valid": false, "error": "no active code found"})
		return
	}

	// Check expiration (15 minutes)
	if time.Since(existing.SentAt) > 15*time.Minute {
		_, _ = cc.EmailCodeCollection.DeleteOne(ctx, bson.M{"_id": existing.ID})
		c.JSON(http.StatusOK, gin.H{"valid": false, "error": "code expired"})
		return
	}

	// Validate code
	if req.Code != existing.Code {
		c.JSON(http.StatusOK, gin.H{"valid": false, "error": "invalid code"})
		return
	}

	// ✅ Code is correct → delete document
	_, err = cc.EmailCodeCollection.DeleteOne(ctx, bson.M{"_id": existing.ID})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to remove code"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"valid": true, "message": "verification successful"})
	log.Printf("✅ Code for %s verified and deleted from DB", req.Email)
}

// func (cc *CodeController) VerifyCode(c *gin.Context) {
// 	var req struct {
// 		Email string `json:"email"`
// 		Code  string `json:"code"`
// 	}

// 	if err := c.BindJSON(&req); err != nil || req.Email == "" || req.Code == "" {
// 		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
// 		return
// 	}

// 	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
// 	defer cancel()

// 	var existing models.EmailCode
// 	err := cc.EmailCodeCollection.FindOne(ctx, bson.M{"email": req.Email, "isActive": true}).Decode(&existing)
// 	if err != nil {
// 		c.JSON(http.StatusOK, gin.H{"valid": false, "error": "no active code found"})
// 		return
// 	}

// 	// Expired (more than 2 minutes)
// 	if time.Since(existing.SentAt) > 2*time.Minute {
// 		_, _ = cc.EmailCodeCollection.DeleteOne(ctx, bson.M{"_id": existing.ID})
// 		c.JSON(http.StatusOK, gin.H{"valid": false, "error": "code expired"})
// 		return
// 	}

// 	// Correct code → delete it immediately
// 	if req.Code == existing.Code {
// 		_, _ = cc.EmailCodeCollection.DeleteOne(ctx, bson.M{"_id": existing.ID})
// 		c.JSON(http.StatusOK, gin.H{"valid": true})
// 		return
// 	}

// 	// Incorrect code
// 	c.JSON(http.StatusOK, gin.H{"valid": false, "error": "invalid code"})
// }

func (cc *CodeController) ConsumeCode(email, code string) (bool, error) {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	var existing models.EmailCode
	err := cc.EmailCodeCollection.FindOne(ctx, bson.M{
		"email":    email,
		"code":     code,
		"isActive": true,
	}).Decode(&existing)
	if err != nil {
		return false, err
	}

	// Expire after 2 minutes
	if time.Since(existing.SentAt) > 2*time.Minute {
		// Delete expired code immediately
		_, _ = cc.EmailCodeCollection.DeleteOne(ctx, bson.M{"_id": existing.ID})
		return false, errors.New("expired")
	}

	// Valid code — delete it after use
	_, _ = cc.EmailCodeCollection.DeleteOne(ctx, bson.M{"_id": existing.ID})

	return true, nil
}

// ConsumeCode checks and deactivates a verification code
// func (cc *CodeController) ConsumeCode(email, code string) (bool, error) {
// 	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
// 	defer cancel()

// 	var existing models.EmailCode
// 	err := cc.EmailCodeCollection.FindOne(ctx, bson.M{
// 		"email":    email,
// 		"code":     code,
// 		"isActive": true,
// 	}).Decode(&existing)
// 	if err != nil {
// 		return false, err
// 	}

// 	if time.Since(existing.SentAt) > 15*time.Minute {
// 		return false, errors.New("expired")
// 	}

// 	_, _ = cc.EmailCodeCollection.UpdateOne(ctx,
// 		bson.M{"_id": existing.ID},
// 		bson.M{"$set": bson.M{"isActive": false}},
// 	)

// 	return true, nil
// }

// Send sign-in code (email or EID)
func (cc *CodeController) GetCodeSignIn(c *gin.Context) {
	var input struct {
		Identifier string `json:"identifier"`
	}

	if err := c.BindJSON(&input); err != nil || input.Identifier == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input"})
		return
	}

	ctx := context.TODO()
	now := time.Now()
	code := utils.GenerateCode(6)
	var user models.User
	var email string

	if strings.Contains(input.Identifier, "@") {
		email = strings.TrimSpace(strings.ToLower(input.Identifier))
		err := cc.UserCollection.FindOne(ctx, bson.M{"email": email}).Decode(&user)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Email not registered"})
			return
		}
	} else {
		err := cc.UserCollection.FindOne(ctx, bson.M{"eid": input.Identifier}).Decode(&user)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid EID"})
			return
		}
		email = user.Email
	}

	// Check rate limiting: max 4 requests within 30 minutes → lock for 30 minutes
	// Track requestCount, firstRequestAt, and lockUntil in the same document
	var existing models.EmailCode
	_ = cc.EmailCodeCollection.FindOne(ctx, bson.M{"email": email}).Decode(&existing)

	// If locked and still within lock window
	if !existing.SentAt.IsZero() {
		// Read potential lockUntil from a separate field via generic map to avoid model changes
		var raw bson.M
		_ = cc.EmailCodeCollection.FindOne(ctx, bson.M{"email": email}).Decode(&raw)
		if raw != nil {
			if lu, ok := raw["lockUntil"].(time.Time); ok {
				if now.Before(lu) {
					c.JSON(http.StatusTooManyRequests, gin.H{"error": "Too many failed attempts. Please try again later."})
					return
				}
			}
		}
	}

	// Determine requestCount window
	var meta bson.M
	_ = cc.EmailCodeCollection.FindOne(ctx, bson.M{"email": email}).Decode(&meta)
	reqCount := 0
	firstReqAt := now
	if meta != nil {
		if v, ok := meta["requestCount"].(int32); ok {
			reqCount = int(v)
		}
		if t, ok := meta["firstRequestAt"].(time.Time); ok && !t.IsZero() {
			firstReqAt = t
		}
		if now.Sub(firstReqAt) > 30*time.Minute {
			reqCount = 0
			firstReqAt = now
		}
	}

	reqCount++
	update := bson.M{
		"$set": bson.M{
			"email":          email,
			"code":           code,
			"sentAt":         now,
			"isActive":       true,
			"firstRequestAt": firstReqAt,
			"requestCount":   reqCount,
		},
	}
	if reqCount >= 4 {
		update["$set"].(bson.M)["lockUntil"] = now.Add(30 * time.Minute)
	} else {
		update["$unset"] = bson.M{"lockUntil": ""}
	}

	_, _ = cc.EmailCodeCollection.UpdateOne(
		ctx,
		bson.M{"email": email},
		update,
		options.Update().SetUpsert(true),
	)

	errMail := services.SendEmail(
		email,
		"Your Login Verification Code",
		fmt.Sprintf("<h3>Your login code is: <b>%s</b></h3>", code),
	)
	if errMail != nil {
		log.Println("Failed to send email:", errMail)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to send email"})
		return
	}

	log.Printf("Login code sent to %s: %s", email, code)
	c.JSON(http.StatusOK, gin.H{"message": "Code sent successfully"})
}

// Verify sign-in code (for UI feedback only - does NOT deactivate the code)
func (cc *CodeController) VerifyCodeSignIn(c *gin.Context) {
	var req struct {
		Identifier string `json:"identifier"` // EID or Email
		Code       string `json:"code"`
	}

	if err := c.ShouldBindJSON(&req); err != nil || req.Identifier == "" || req.Code == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request", "valid": false})
		return
	}

	ctx := context.TODO()
	var user models.User
	var email string

	// Resolve identifier to email
	if strings.Contains(req.Identifier, "@") {
		email = strings.TrimSpace(strings.ToLower(req.Identifier))
		err := cc.UserCollection.FindOne(ctx, bson.M{"email": email}).Decode(&user)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Email not registered", "valid": false})
			return
		}
	} else {
		err := cc.UserCollection.FindOne(ctx, bson.M{"eid": req.Identifier}).Decode(&user)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid EID", "valid": false})
			return
		}
		email = user.Email
	}

	// Lookup code using resolved email
	filter := bson.M{
		"email":    email,
		"code":     req.Code,
		"isActive": true,
	}

	var codeDoc models.EmailCode
	err := cc.EmailCodeCollection.FindOne(ctx, filter).Decode(&codeDoc)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid or expired code", "valid": false})
		return
	}

	// 2-minute validity for sign-in codes
	if time.Since(codeDoc.SentAt) > 2*time.Minute {
		// delete expired code immediately
		_, _ = cc.EmailCodeCollection.DeleteOne(ctx, bson.M{"_id": codeDoc.ID})
		c.JSON(http.StatusBadRequest, gin.H{
			"error": "Code expired, please request a new one",
			"valid": false,
		})
		return
	}

	// IMPORTANT: DO NOT deactivate the code here!
	// The code will be deactivated/deleted only during actual sign-in
	// This endpoint is just for UI feedback

	c.JSON(http.StatusOK, gin.H{"valid": true})
}

// Setup TTL for auto-delete after 2 minutes
func SetupEmailCodeTTL(collection *mongo.Collection) {
	indexModel := mongo.IndexModel{
		Keys:    bson.M{"sentAt": 1},
		Options: options.Index().SetExpireAfterSeconds(2 * 60),
	}

	_, err := collection.Indexes().CreateOne(context.TODO(), indexModel)
	if err != nil {
		fmt.Println("⚠️ Failed to create TTL index for email_codes:", err)
	} else {
		fmt.Println("✅ TTL index set: email_codes expire after 2 minutes")
	}
}

func (cc *CodeController) SendResetCode(c *gin.Context) {
	var req struct {
		Identifier string `json:"identifier"` // Email or EID
	}

	if err := c.ShouldBindJSON(&req); err != nil || req.Identifier == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Identifier required"})
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	var user models.User
	var email string

	// Resolve identifier to email
	if strings.Contains(req.Identifier, "@") {
		email = strings.TrimSpace(strings.ToLower(req.Identifier))
		if err := cc.UserCollection.FindOne(ctx, bson.M{"email": email}).Decode(&user); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Email not registered"})
			return
		}
	} else {
		if err := cc.UserCollection.FindOne(ctx, bson.M{"eid": req.Identifier}).Decode(&user); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid EID"})
			return
		}
		email = user.Email
	}

	// Check if an active code exists
	var existing models.EmailCode
	err := cc.EmailCodeCollection.FindOne(ctx, bson.M{"email": email, "isActive": true}).Decode(&existing)
	if err == nil && time.Since(existing.SentAt) < 2*time.Minute { // 2-min validity
		log.Println("Resending existing reset code:", existing.Code)
		c.JSON(http.StatusOK, gin.H{"code": existing.Code})
		return
	}

	// Generate new code
	code := utils.GenerateCode(6)
	resetDoc := models.EmailCode{
		Email:    email,
		Code:     code,
		SentAt:   time.Now(),
		IsActive: true,
	}

	_, err = cc.EmailCodeCollection.UpdateOne(
		ctx,
		bson.M{"email": email},
		bson.M{"$set": resetDoc},
		options.Update().SetUpsert(true),
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}

	// Send email
	if err := services.SendEmail(
		email,
		"Password Reset Code",
		fmt.Sprintf("<h3>Your password reset code is: <b>%s</b></h3>", code),
	); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to send email"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"code": code})
}

// func (cc *CodeController) SendResetCode(c *gin.Context) {
// 	var req struct {
// 		Identifier string `json:"identifier"` // Email or EID
// 	}

// 	if err := c.ShouldBindJSON(&req); err != nil || req.Identifier == "" {
// 		c.JSON(http.StatusBadRequest, gin.H{"error": "Identifier required"})
// 		return
// 	}

// 	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
// 	defer cancel()

// 	var user models.User
// 	var email string

// 	// Resolve identifier to email
// 	if strings.Contains(req.Identifier, "@") {
// 		email = strings.TrimSpace(strings.ToLower(req.Identifier))
// 		if err := cc.UserCollection.FindOne(ctx, bson.M{"email": email}).Decode(&user); err != nil {
// 			c.JSON(http.StatusBadRequest, gin.H{"error": "Email not registered"})
// 			return
// 		}
// 	} else {
// 		if err := cc.UserCollection.FindOne(ctx, bson.M{"eid": req.Identifier}).Decode(&user); err != nil {
// 			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid EID"})
// 			return
// 		}
// 		email = user.Email
// 	}

// 	// Generate and store reset code
// 	code := utils.GenerateCode(6)
// 	resetDoc := models.EmailCode{
// 		Email:    email,
// 		Code:     code,
// 		SentAt:   time.Now(),
// 		IsActive: true,
// 	}

// 	_, err := cc.EmailCodeCollection.UpdateOne(
// 		ctx,
// 		bson.M{"email": email},
// 		bson.M{"$set": resetDoc},
// 		options.Update().SetUpsert(true),
// 	)
// 	if err != nil {
// 		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
// 		return
// 	}

// 	// Send email
// 	if err := services.SendEmail(
// 		email,
// 		"Password Reset Code",
// 		fmt.Sprintf("<h3>Your password reset code is: <b>%s</b></h3>", code),
// 	); err != nil {
// 		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to send email"})
// 		return
// 	}

// 	c.JSON(http.StatusOK, gin.H{"message": "Reset code sent"})
// }

// func (cc *CodeController) VerifyResetCode(c *gin.Context) {
// 	var req struct {
// 		Identifier string `json:"identifier"` // Email or EID
// 		Code       string `json:"code"`
// 	}

// 	if err := c.ShouldBindJSON(&req); err != nil || req.Identifier == "" || req.Code == "" {
// 		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
// 		return
// 	}

// 	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
// 	defer cancel()

// 	var user models.User
// 	var email string

// 	// Resolve identifier to email
// 	if strings.Contains(req.Identifier, "@") {
// 		email = strings.TrimSpace(strings.ToLower(req.Identifier))
// 		if err := cc.UserCollection.FindOne(ctx, bson.M{"email": email}).Decode(&user); err != nil {
// 			c.JSON(http.StatusBadRequest, gin.H{"error": "Email not registered"})
// 			return
// 		}
// 	} else {
// 		if err := cc.UserCollection.FindOne(ctx, bson.M{"eid": req.Identifier}).Decode(&user); err != nil {
// 			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid EID"})
// 			return
// 		}
// 		email = user.Email
// 	}

// 	var existing models.EmailCode
// 	err := cc.EmailCodeCollection.FindOne(ctx, bson.M{"email": email, "isActive": true}).Decode(&existing)
// 	if err != nil {
// 		c.JSON(http.StatusOK, gin.H{"valid": false, "error": "no active code found"})
// 		return
// 	}

// 	// Expiry check
// 	if time.Since(existing.SentAt) > 2*time.Minute {
// 		_, _ = cc.EmailCodeCollection.DeleteOne(ctx, bson.M{"_id": existing.ID})
// 		c.JSON(http.StatusOK, gin.H{"valid": false, "error": "code expired"})
// 		return
// 	}

// 	if req.Code == existing.Code {
// 		_, _ = cc.EmailCodeCollection.UpdateOne(ctx,
// 			bson.M{"_id": existing.ID},
// 			bson.M{"$set": bson.M{"isActive": false}},
// 		)
// 		c.JSON(http.StatusOK, gin.H{"valid": true})
// 		return
// 	}

// 	c.JSON(http.StatusOK, gin.H{"valid": false})
// }

func (cc *CodeController) VerifyResetCode(c *gin.Context) {
	var req struct {
		Identifier string `json:"identifier"` // Email or EID
		Code       string `json:"code"`
	}

	if err := c.ShouldBindJSON(&req); err != nil || req.Identifier == "" || req.Code == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
	defer cancel()

	var user models.User
	var email string

	// Resolve identifier to email
	if strings.Contains(req.Identifier, "@") {
		email = strings.TrimSpace(strings.ToLower(req.Identifier))
		if err := cc.UserCollection.FindOne(ctx, bson.M{"email": email}).Decode(&user); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Email not registered"})
			return
		}
	} else {
		if err := cc.UserCollection.FindOne(ctx, bson.M{"eid": req.Identifier}).Decode(&user); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid EID"})
			return
		}
		email = user.Email
	}

	// Lookup code using resolved email
	var codeDoc models.EmailCode
	err := cc.EmailCodeCollection.FindOne(ctx, bson.M{
		"email":    email,
		"code":     req.Code,
		"isActive": true,
	}).Decode(&codeDoc)

	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid or expired code"})
		return
	}

	// 5-minute validity
	if time.Since(codeDoc.SentAt) > 2*time.Minute {
		// _, _ = cc.EmailCodeCollection.DeleteOne(ctx, bson.M{"_id": codeDoc.ID})
		c.JSON(http.StatusBadRequest, gin.H{"error": "Code expired"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"verified": true})
}

func (cc *CodeController) GetEIDCode(c *gin.Context) {
	var req struct {
		Email string `json:"email"`
	}

	if err := c.BindJSON(&req); err != nil || req.Email == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Check if user exists
	var existingUser bson.M
	if errUser := cc.UserCollection.FindOne(ctx, bson.M{"email": req.Email}).Decode(&existingUser); errUser != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Email not registered"})
		return
	}

	// Deactivate all previous active codes for this email
	_, _ = cc.EmailCodeCollection.UpdateMany(
		ctx,
		bson.M{"email": req.Email, "isActive": true},
		bson.M{"$set": bson.M{"isActive": false}},
	)

	// Generate new code
	newCode := utils.GenerateCode(6)
	emailDoc := models.EmailCode{
		Email:    req.Email,
		Code:     newCode,
		SentAt:   time.Now(),
		IsActive: true,
	}

	_, err := cc.EmailCodeCollection.InsertOne(
		ctx,
		emailDoc,
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "database error"})
		return
	}

	// Send email
	if errMail := services.SendEmail(
		req.Email,
		"Your EID Code",
		fmt.Sprintf("<h1>Your code is: %s</h1>", newCode),
	); errMail != nil {
		log.Println("Failed to send email:", errMail)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to send email"})
		return
	}

	log.Println("Generated new code:", newCode)
	c.JSON(http.StatusOK, gin.H{"code": newCode})
}

// func (cc *CodeController) VerifyEIDCode(c *gin.Context) {
// 	var req struct {
// 		Email string `json:"email"`
// 		Code  string `json:"code"`
// 	}

// 	if err := c.BindJSON(&req); err != nil || req.Email == "" || req.Code == "" {
// 		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
// 		return
// 	}

// 	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
// 	defer cancel()

// 	var existing models.EmailCode
// 	err := cc.EmailCodeCollection.FindOne(ctx, bson.M{"email": req.Email, "isActive": true}).Decode(&existing)
// 	if err != nil {
// 		c.JSON(http.StatusOK, gin.H{"valid": false, "error": "no active code found"})
// 		return
// 	}

// 	// Expired code
// 	if time.Since(existing.SentAt) > 15*time.Minute {
// 		_, _ = cc.EmailCodeCollection.DeleteOne(ctx, bson.M{"_id": existing.ID})
// 		c.JSON(http.StatusOK, gin.H{"valid": false, "error": "code expired"})
// 		return
// 	}

// 	// Correct code
// 	if req.Code == existing.Code {
// 		_, _ = cc.EmailCodeCollection.UpdateOne(ctx,
// 			bson.M{"_id": existing.ID},
// 			bson.M{"$set": bson.M{"isActive": false}},
// 		)
// 		c.JSON(http.StatusOK, gin.H{"valid": true})
// 		return
// 	}

// 	// Incorrect code
// 	c.JSON(http.StatusOK, gin.H{"valid": false})
// }

// func (cc *CodeController) VerifyEIDCode(c *gin.Context) {
// 	var req struct {
// 		Email string `json:"email"`
// 		Code  string `json:"code"`
// 	}

// 	if err := c.BindJSON(&req); err != nil || req.Email == "" || req.Code == "" {
// 		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
// 		return
// 	}

// 	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
// 	defer cancel()

// 	var existing models.EmailCode
// 	err := cc.EmailCodeCollection.FindOne(ctx, bson.M{"email": req.Email, "isActive": true}).Decode(&existing)
// 	if err != nil {
// 		c.JSON(http.StatusOK, gin.H{"valid": false, "error": "no active code found"})
// 		return
// 	}

// 	valid := req.Code == existing.Code && time.Since(existing.SentAt) < 15*time.Minute
// 	if valid {
// 		// deactivate after use
// 		// _, _ = cc.EmailCodeCollection.UpdateOne(ctx,
// 		// 	bson.M{"_id": existing.ID},
// 		// 	bson.M{"$set": bson.M{"isActive": false}},
// 		// )
// 		c.JSON(http.StatusOK, gin.H{"valid": true})
// 	} else {
// 		c.JSON(http.StatusOK, gin.H{"valid": false})
// 	}
// }

func (cc *CodeController) VerifyEIDCode(c *gin.Context) {
	var req struct {
		Email string `json:"email"`
		Code  string `json:"code"`
	}

	if err := c.BindJSON(&req); err != nil || req.Email == "" || req.Code == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	var existing models.EmailCode
	err := cc.EmailCodeCollection.FindOne(ctx, bson.M{"email": req.Email, "isActive": true}).Decode(&existing)
	if err != nil {
		c.JSON(http.StatusOK, gin.H{"valid": false, "error": "no active code found"})
		return
	}

	// Set 2-minute expiration
	expired := time.Since(existing.SentAt) > 2*time.Minute
	if expired {
		// delete the expired code
		_, _ = cc.EmailCodeCollection.DeleteOne(ctx, bson.M{"_id": existing.ID})
		c.JSON(http.StatusOK, gin.H{"valid": false, "error": "code expired"})
		return
	}

	if req.Code == existing.Code {
		c.JSON(http.StatusOK, gin.H{"valid": true})
		return
	}

	c.JSON(http.StatusOK, gin.H{"valid": false, "error": "invalid code"})
}

// ForgotEID handles sending the EID to the user's email
// func (cc *CodeController) ForgotEID(c *gin.Context) {
// 	var req struct {
// 		Email string `json:"email"`
// 	}

// 	if err := c.ShouldBindJSON(&req); err != nil || req.Email == "" {
// 		c.JSON(http.StatusBadRequest, gin.H{"error": "Email is required"})
// 		return
// 	}

// 	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
// 	defer cancel()

// 	// Find user by email
// 	var user models.User
// 	err := cc.UserCollection.FindOne(ctx, bson.M{"email": strings.ToLower(req.Email)}).Decode(&user)
// 	if err != nil {
// 		c.JSON(http.StatusNotFound, gin.H{"error": "Email not registered"})
// 		return
// 	}

// 	// Send EID via email
// 	err = services.SendEmail(
// 		user.Email,
// 		"Your EID",
// 		fmt.Sprintf("<h3>Your EID is: <b>%s</b></h3>", user.EID),
// 	)
// 	if err != nil {
// 		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to send email"})
// 		return
// 	}

// 	_, _ = cc.EmailCodeCollection.UpdateOne(
// 		ctx,
// 		bson.M{"email": user.Email, "isActive": true},
// 		bson.M{"$set": bson.M{"isActive": false}},
// 	)

//		c.JSON(http.StatusOK, gin.H{"message": "EID sent successfully"})
//	}
func (cc *CodeController) ForgotEID(c *gin.Context) {
	var req struct {
		Email string `json:"email"`
	}

	if err := c.ShouldBindJSON(&req); err != nil || req.Email == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Email is required"})
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Find user by email
	var user models.User
	err := cc.UserCollection.FindOne(ctx, bson.M{"email": strings.ToLower(req.Email)}).Decode(&user)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "Email not registered"})
		return
	}

	// Send EID via email
	err = services.SendEmail(
		user.Email,
		"Your EID",
		fmt.Sprintf("<h3>Your EID is: <b>%s</b></h3>", user.EID),
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to send email"})
		return
	}

	// Delete any previous active codes for this email
	_, _ = cc.EmailCodeCollection.DeleteMany(ctx, bson.M{"email": user.Email, "isActive": true})

	c.JSON(http.StatusOK, gin.H{"message": "EID sent successfully"})
}
