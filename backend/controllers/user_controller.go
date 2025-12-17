// package controllers

// import (
// 	"context"
// 	"flutter_project_backend/models"
// 	"flutter_project_backend/utils"
// 	"fmt"
// 	"net/http"
// 	"regexp"
// 	"strings"
// 	"time"

// 	"github.com/gin-gonic/gin"
// 	"go.mongodb.org/mongo-driver/bson"
// 	"go.mongodb.org/mongo-driver/mongo"
// 	"go.mongodb.org/mongo-driver/mongo/options"
// 	"golang.org/x/crypto/bcrypt"
// )

// type UserController struct {
// 	UserCollection *mongo.Collection
// 	CodeController *CodeController // optional, if you plan to use it
// }

// // ---------------- Email Validation ----------------
// // func isValidEmail(email string) bool {
// // 	// RFC 5322 compliant regex for most email addresses
// // 	re := regexp.MustCompile(`^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$`)
// // 	return re.MatchString(email)
// // }

// // ---------------- Send Verification Code ----------------
// func (uc *UserController) SendCode(c *gin.Context) {
// 	var input struct {
// 		Email string `json:"email"`
// 		Code  string `json:"code"` // optional, if needed
// 	}

// 	if err := c.BindJSON(&input); err != nil {
// 		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input"})
// 		return
// 	}

// 	// Trim and lowercase
// 	email := strings.TrimSpace(strings.ToLower(input.Email))

// 	// Validate email
// 	// if !isValidEmail(email) {
// 	// 	c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid email format"})
// 	// 	return
// 	// }

// 	// Check if user exists
// 	var user models.User
// 	err := uc.UserCollection.FindOne(context.TODO(), bson.M{"email": input.Email}).Decode(&user)

// 	now := time.Now()
// 	var code string

// 	if err == nil {
// 		// User exists
// 		if now.Sub(user.EmailCodeSent) < 15*time.Minute {
// 			code = user.EmailCode // reuse old code
// 		} else {
// 			code = utils.GenerateCode(6)
// 		}
// 		_, _ = uc.UserCollection.UpdateOne(
// 			context.TODO(),
// 			bson.M{"email": email},
// 			bson.M{"$set": bson.M{"emailCode": code, "emailCodeSent": now}},
// 		)
// 	} else {
// 		// New user
// 		code = utils.GenerateCode(6)
// 		newUser := models.User{
// 			Email:         email,
// 			EmailCode:     code,
// 			EmailCodeSent: now,
// 		}
// 		_, _ = uc.UserCollection.InsertOne(context.TODO(), newUser)
// 	}

// 	// TODO: integrate email service
// 	fmt.Println("Verification code:", code)

// 	c.JSON(http.StatusOK, gin.H{"message": "Code sent"})
// }

// // ---------------- Register User ----------------
// func (uc *UserController) Register(c *gin.Context) {
// 	var input struct {
// 		FirstName       string          `json:"firstName"`
// 		LastName        string          `json:"lastName"`
// 		Email           string          `json:"email"`
// 		EmailCode       string          `json:"emailCode"`
// 		SponsorCode     string          `json:"sponsorCode"`
// 		Gender          string          `json:"gender"`
// 		Country         models.Country  `json:"country"`
// 		Language        models.Language `json:"language"`
// 		DateOfBirth     string          `json:"dob"`
// 		Password        string          `json:"password"`
// 		ConfirmPassword string          `json:"confirmPassword"`
// 	}

// 	if err := c.BindJSON(&input); err != nil {
// 		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input"})
// 		return
// 	}

// 	// Trim and lowercase
// 	email := strings.TrimSpace(strings.ToLower(input.Email))

// 	// Validate email
// 	if !isValidEmail(email) {
// 		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid email format"})
// 		return
// 	}

// 	// Password match
// 	if input.Password != input.ConfirmPassword {
// 		c.JSON(http.StatusBadRequest, gin.H{"error": "Passwords do not match"})
// 		return
// 	}

// 	// Validate email code
// 	var user models.User
// 	err := uc.UserCollection.FindOne(context.TODO(), bson.M{"email": email}).Decode(&user)
// 	if err != nil || user.EmailCode != input.EmailCode || time.Since(user.EmailCodeSent) > 15*time.Minute {
// 		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid or expired email code"})
// 		return
// 	}

// 	// Parse DOB
// 	dob, err := time.Parse("2006-01-02", input.DateOfBirth)
// 	if err != nil {
// 		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid date format. Use YYYY-MM-DD"})
// 		return
// 	}

// 	// Hash password
// 	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(input.Password), bcrypt.DefaultCost)
// 	if err != nil {
// 		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to hash password"})
// 		return
// 	}

// 	// Create or update user
// 	update := bson.M{
// 		"$set": bson.M{
// 			"firstName":   input.FirstName,
// 			"lastName":    input.LastName,
// 			"sponsorCode": input.SponsorCode,
// 			"gender":      input.Gender,
// 			"country":     input.Country,
// 			"language":    input.Language,
// 			"dob":         dob,
// 			"password":    string(hashedPassword),
// 		},
// 	}

// 	_, err = uc.UserCollection.UpdateOne(
// 		context.TODO(),
// 		bson.M{"email": email},
// 		update,
// 		options.Update().SetUpsert(true),
// 	)
// 	if err != nil {
// 		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to register user"})
// 		return
// 	}

//		c.JSON(http.StatusOK, gin.H{"message": "Registration successful"})
//	}

package controllers

import (
	"context"
	"flutter_project_backend/models"

	"flutter_project_backend/utils"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
	"github.com/pquerna/otp/totp"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
	"golang.org/x/crypto/bcrypt"
)

type UserController struct {
	UserCollection *mongo.Collection
	CodeController *CodeController
}

// Send verification code
func (uc *UserController) SendCode(c *gin.Context) {
	var input struct {
		Email string `json:"email"`
		Code  string `json:"code"`
	}
	if err := c.BindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input"})
		return
	}

	// Normalize email
	email := strings.TrimSpace(strings.ToLower(input.Email))

	var user models.User
	err := uc.UserCollection.FindOne(context.TODO(), bson.M{"email": email}).Decode(&user)

	code := ""
	now := time.Now()

	if err == nil {
		// User exists
		if now.Sub(user.EmailCodeSent) < 15*time.Minute {
			code = user.EmailCode // reuse old code
		} else {
			code = utils.GenerateCode(6)
		}
		_, _ = uc.UserCollection.UpdateOne(
			context.TODO(),
			bson.M{"email": email},
			bson.M{"$set": bson.M{"emailCode": code, "emailCodeSent": now}},
		)
	} else {
		// New user
		code = utils.GenerateCode(6)
		newUser := models.User{
			Email:         email,
			EmailCode:     code,
			EmailCodeSent: now,
		}
		_, _ = uc.UserCollection.InsertOne(context.TODO(), newUser)
	}

	// TODO: integrate email service
	fmt.Println("Verification code:", code)

	c.JSON(http.StatusOK, gin.H{"message": "Code sent"})
}

// Register user
func (uc *UserController) Register(c *gin.Context) {
	var input struct {
		FirstName       string          `json:"firstName"`
		LastName        string          `json:"lastName"`
		Email           string          `json:"email"`
		EmailCode       string          `json:"emailCode"`
		SponsorCode     string          `json:"sponsorCode"`
		Gender          string          `json:"gender"`
		Country         models.Country  `json:"country"`
		Language        models.Language `json:"language"`
		DateOfBirth     string          `json:"dob"`
		Password        string          `json:"password"`
		ConfirmPassword string          `json:"confirmPassword"`
	}

	if err := c.BindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input"})
		return
	}

	if input.Password != input.ConfirmPassword {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Passwords do not match"})
		return
	}

	// Normalize email
	email := strings.TrimSpace(strings.ToLower(input.Email))

	// Parse DOB
	dob, err := time.Parse("2006-01-02", input.DateOfBirth)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid date format. Use YYYY-MM-DD"})
		return
	}

	// Hash password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(input.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to hash password"})
		return
	}

	// Check if user already exists
	var existing models.User
	err = uc.UserCollection.FindOne(context.TODO(), bson.M{"email": email}).Decode(&existing)

	var eid string
	if err == mongo.ErrNoDocuments {
		// New user — generate new EID
		eid, err = utils.GenerateEID()
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate EID"})
			return
		}
		eid = strings.ToLower(eid)
		// eid = strings.ToLower(utils.GenerateEID())
	} else if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	} else {
		// Existing user — check if they have an EID
		if existing.EID == "" {
			eid, err = utils.GenerateEID()
			if err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate EID"})
				return
			}
			eid = strings.ToLower(eid)
			// No EID exists, generate one
			// eid = strings.ToLower(utils.GenerateEID())
		} else {
			// Keep their existing EID
			eid = strings.ToLower(existing.EID)
		}
	}

	// Prepare update / insert
	update := bson.M{
		"$set": bson.M{
			"firstName":   input.FirstName,
			"lastName":    input.LastName,
			"sponsorCode": input.SponsorCode,
			"gender":      input.Gender,
			"country":     input.Country,
			"language":    input.Language,
			"dob":         dob,
			"password":    string(hashedPassword),
			"email":       email, // store normalized email
			"eid":         eid,   // store normalized eid
			"createdAt":   time.Now(),
		},
	}

	_, err = uc.UserCollection.UpdateOne(
		context.TODO(),
		bson.M{"email": email},
		update,
		options.Update().SetUpsert(true),
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to register user"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "Registration successful",
		"eid":     eid,
	})
}

// Migration function - Run this ONCE to add EIDs to existing users
func (uc *UserController) MigrateUsersEID(c *gin.Context) {
	// Use bson.M to avoid decoding issues with mismatched types
	cursor, err := uc.UserCollection.Find(context.TODO(), bson.M{})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to fetch users"})
		return
	}

	fmt.Println("\n=== MIGRATION START ===")
	fmt.Println("Checking all users:")

	type UserIDEmail struct {
		ID    interface{} `bson:"_id"`
		Email string      `bson:"email"`
		EID   string      `bson:"eid"`
	}

	var usersToUpdate []UserIDEmail
	for cursor.Next(context.TODO()) {
		var user UserIDEmail
		if err := cursor.Decode(&user); err != nil {
			fmt.Printf("Error decoding user: %v\n", err)
			continue
		}

		fmt.Printf("User: %s, EID: '%s', EID Length: %d\n", user.Email, user.EID, len(user.EID))

		// Check if EID is empty or missing
		if user.EID == "" {
			usersToUpdate = append(usersToUpdate, user)
			fmt.Printf("  -> Will update this user (empty EID)\n")
		}
	}
	cursor.Close(context.TODO())

	fmt.Printf("\nFound %d users that need EID\n", len(usersToUpdate))

	// Now update them
	updated := 0
	for _, user := range usersToUpdate {
		eid, err := utils.GenerateEID()
		if err != nil {
			fmt.Printf("Error generating EID for user %s: %v\n", user.Email, err)
			continue
		}

		newEID := strings.ToLower(eid)

		result, err := uc.UserCollection.UpdateOne(
			context.TODO(),
			bson.M{"_id": user.ID},
			bson.M{"$set": bson.M{"eid": newEID}},
		)
		if err != nil {
			fmt.Printf("Error updating user %s: %v\n", user.Email, err)
			continue
		}

		if result.ModifiedCount > 0 {
			updated++
			fmt.Printf("✓ Updated user %s with EID: %s\n", user.Email, newEID)
		} else {
			fmt.Printf("✗ Failed to update user %s (no rows modified)\n", user.Email)
		}
	}

	fmt.Println("=== MIGRATION END ===\n")

	c.JSON(http.StatusOK, gin.H{
		"message":       "Migration completed",
		"updated":       updated,
		"total_checked": len(usersToUpdate),
	})
}

// Sign in user (by EID or Email) with remember me + JWT + email code verification

func (uc *UserController) SignIn(c *gin.Context) {
	var input struct {
		Identifier string `json:"identifier"` // EID or Email
		Password   string `json:"password"`
		Code       string `json:"code"` // verification code
		RememberMe bool   `json:"rememberMe"`
	}

	if err := c.BindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input"})
		return
	}

	if input.Identifier == "" || input.Password == "" || input.Code == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "EID/Email, password, and code are required"})
		return
	}

	ctx := context.TODO()
	var user models.User
	var email string

	// --- Resolve identifier to email ---
	if strings.Contains(input.Identifier, "@") {
		email = strings.TrimSpace(strings.ToLower(input.Identifier))
		err := uc.UserCollection.FindOne(ctx, bson.M{"email": email}).Decode(&user)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Email not registered"})
			return
		}
	} else {
		err := uc.UserCollection.FindOne(ctx, bson.M{"eid": input.Identifier}).Decode(&user)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid EID"})
			return
		}
		email = user.Email
	}

	// --- PASSWORD VERIFICATION ---
	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(input.Password)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid password"})
		return
	}

	filter := bson.M{
		"email":    email,
		"code":     input.Code,
		"isActive": true,
	}

	var codeDoc models.EmailCode
	err := uc.CodeController.EmailCodeCollection.FindOne(ctx, filter).Decode(&codeDoc)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid or expired verification code"})
		return
	}
	// --- DELETE USED CODE ---
	_, err = uc.CodeController.EmailCodeCollection.DeleteOne(ctx, bson.M{"_id": codeDoc.ID})
	if err != nil {
		log.Printf("Warning: Failed to delete used code: %v", err)
	}

	// --- GENERATE JWT ---
	expirationTime := time.Now().Add(24 * time.Hour)
	if input.RememberMe {
		expirationTime = time.Now().Add(15 * 24 * time.Hour)
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id": fmt.Sprintf("%v", user.ID),
		"eid":     user.EID,
		"email":   user.Email,
		"exp":     expirationTime.Unix(),
	})

	secret := os.Getenv("JWT_SECRET")
	tokenString, err := token.SignedString([]byte(secret))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
		return
	}

	c.SetCookie("token", tokenString, int(expirationTime.Sub(time.Now()).Seconds()), "/", "", false, true)

	c.JSON(http.StatusOK, gin.H{
		"message": "Sign in successful",
		"token":   tokenString,
		"user": gin.H{
			"id":                user.ID,
			"eid":               user.EID,
			"email":             user.Email,
			"firstName":         user.FirstName,
			"lastName":          user.LastName,
			"pinRegistered":     user.Pin != "",
			"patternRegistered": user.PatternHash != "",
		},
	})
}

// func (uc *UserController) SignIn(c *gin.Context) {
// 	var input struct {
// 		Identifier string `json:"identifier"` // EID or Email
// 		Password   string `json:"password"`
// 		Code       string `json:"code"` // verification code
// 		RememberMe bool   `json:"rememberMe"`
// 	}

// 	if err := c.BindJSON(&input); err != nil {
// 		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input"})
// 		return
// 	}

// 	if input.Identifier == "" || input.Password == "" || input.Code == "" {
// 		c.JSON(http.StatusBadRequest, gin.H{"error": "EID/Email, password, and code are required"})
// 		return
// 	}

// 	ctx := context.TODO()
// 	var user models.User
// 	var email string

// 	// --- Resolve identifier to email
// 	if strings.Contains(input.Identifier, "@") {
// 		email = strings.TrimSpace(strings.ToLower(input.Identifier))
// 		err := uc.UserCollection.FindOne(ctx, bson.M{"email": email}).Decode(&user)
// 		if err != nil {
// 			c.JSON(http.StatusUnauthorized, gin.H{"error": "Email not registered"})
// 			return
// 		}
// 	} else {
// 		err := uc.UserCollection.FindOne(ctx, bson.M{"eid": input.Identifier}).Decode(&user)
// 		if err != nil {
// 			c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid EID"})
// 			return
// 		}
// 		email = user.Email
// 	}

// 	now := time.Now()

// 	// --- ACCOUNT LOCK HANDLING ---
// 	if !user.AccountLockUntil.IsZero() && now.Before(user.AccountLockUntil) {
// 		remaining := user.AccountLockUntil.Sub(now)
// 		h := int(remaining.Hours())
// 		m := int(remaining.Minutes()) % 60
// 		s := int(remaining.Seconds()) % 60
// 		c.JSON(http.StatusLocked, gin.H{
// 			"error":            fmt.Sprintf("Too many failed attempts. Your account is locked for %02dh:%02dm:%02ds.", h, m, s),
// 			"remainingSeconds": int(remaining.Seconds()),
// 		})
// 		return
// 	}

// 	// --- Reset attempts if lock expired ---
// 	if !user.AccountLockUntil.IsZero() && now.After(user.AccountLockUntil) {
// 		_, _ = uc.UserCollection.UpdateOne(ctx,
// 			bson.M{"email": email},
// 			bson.M{
// 				"$set": bson.M{
// 					"failedAttempts":   0,
// 					"accountLockUntil": time.Time{},
// 				},
// 			},
// 		)
// 		user.FailedAttempts = 0
// 		user.AccountLockUntil = time.Time{}
// 	}

// 	// --- PASSWORD VERIFICATION ---
// 	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(input.Password)); err != nil {
// 		// Increment failed attempts
// 		update := bson.M{
// 			"$set": bson.M{"lastFailedAt": now},
// 			"$inc": bson.M{"failedAttempts": 1},
// 		}

// 		user.FailedAttempts++
// 		if user.FailedAttempts >= 5 {
// 			lockUntil := now.Add(24 * time.Hour)
// 			update["$set"].(bson.M)["accountLockUntil"] = lockUntil
// 			_, _ = uc.UserCollection.UpdateOne(ctx, bson.M{"email": email}, update)

// 			c.JSON(http.StatusLocked, gin.H{
// 				"error":            "Account locked for 24 hours due to too many failed attempts",
// 				"remainingSeconds": int(time.Until(lockUntil).Seconds()),
// 			})
// 			return
// 		}

// 		_, _ = uc.UserCollection.UpdateOne(ctx, bson.M{"email": email}, update)
// 		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid password"})
// 		return
// 	}

// 	// --- VERIFY EMAIL CODE ---
// 	if uc.CodeController == nil {
// 		c.JSON(http.StatusInternalServerError, gin.H{"error": "CodeController not initialized"})
// 		return
// 	}

// 	filter := bson.M{
// 		"email":    email,
// 		"code":     input.Code,
// 		"isActive": true,
// 	}

// 	var codeDoc models.EmailCode
// 	err := uc.CodeController.EmailCodeCollection.FindOne(ctx, filter).Decode(&codeDoc)
// 	if err != nil {
// 		// Increment failedAttempts for invalid code
// 		update := bson.M{
// 			"$set": bson.M{"lastFailedAt": now},
// 			"$inc": bson.M{"failedAttempts": 1},
// 		}
// 		user.FailedAttempts++
// 		if user.FailedAttempts >= 5 {
// 			lockUntil := now.Add(24 * time.Hour)
// 			update["$set"].(bson.M)["accountLockUntil"] = lockUntil
// 			_, _ = uc.UserCollection.UpdateOne(ctx, bson.M{"email": email}, update)
// 			c.JSON(http.StatusLocked, gin.H{
// 				"error":            fmt.Sprintf("Too many failed attempts. Your account is locked for 24 hours."),
// 				"remainingSeconds": int(time.Until(lockUntil).Seconds()),
// 			})
// 			return
// 		}

// 		_, _ = uc.UserCollection.UpdateOne(ctx, bson.M{"email": email}, update)
// 		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid or expired verification code"})
// 		return
// 	}

// 	// --- CODE EXPIRATION CHECK (2 minutes) ---
// 	if time.Since(codeDoc.SentAt) > 2*time.Minute {
// 		_, _ = uc.UserCollection.UpdateOne(ctx, bson.M{"email": email},
// 			bson.M{
// 				"$set": bson.M{"lastFailedAt": now},
// 				"$inc": bson.M{"failedAttempts": 1},
// 			})
// 		_, _ = uc.CodeController.EmailCodeCollection.DeleteOne(ctx, bson.M{"_id": codeDoc.ID})

// 		c.JSON(http.StatusUnauthorized, gin.H{"error": "Verification code expired"})
// 		return
// 	}

// 	// --- DELETE USED CODE ---
// 	_, err = uc.CodeController.EmailCodeCollection.DeleteOne(ctx, bson.M{"_id": codeDoc.ID})
// 	if err != nil {
// 		log.Printf("Warning: Failed to delete used code: %v", err)
// 	}

// 	// --- RESET FAILED ATTEMPTS AFTER SUCCESSFUL LOGIN ---
// 	_, _ = uc.UserCollection.UpdateOne(ctx, bson.M{"email": email},
// 		bson.M{
// 			"$set":   bson.M{"failedAttempts": 0},
// 			"$unset": bson.M{"accountLockUntil": ""},
// 		})

// 	// --- GENERATE JWT ---
// 	expirationTime := time.Now().Add(24 * time.Hour)
// 	if input.RememberMe {
// 		expirationTime = time.Now().Add(15 * 24 * time.Hour)
// 	}

// 	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
// 		"user_id": fmt.Sprintf("%v", user.ID),
// 		"eid":     user.EID,
// 		"email":   user.Email,
// 		"exp":     expirationTime.Unix(),
// 	})

// 	secret := os.Getenv("JWT_SECRET")
// 	tokenString, err := token.SignedString([]byte(secret))
// 	if err != nil {
// 		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to generate token"})
// 		return
// 	}

// 	c.SetCookie("token", tokenString, int(expirationTime.Sub(time.Now()).Seconds()), "/", "", false, true)

// 	c.JSON(http.StatusOK, gin.H{
// 		"message": "Sign in successful",
// 		"token":   tokenString,
// 		"user": gin.H{
// 			"id":        user.ID,
// 			"eid":       user.EID,
// 			"email":     user.Email,
// 			"firstName": user.FirstName,
// 			"lastName":  user.LastName,
// 		},
// 	})
// }

func (uc *UserController) ValidateCredentials(c *gin.Context) {
	var input struct {
		Identifier string `json:"identifier"`
		Password   string `json:"password"`
	}

	if err := c.BindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input"})
		return
	}

	if input.Identifier == "" || input.Password == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Identifier and password are required"})
		return
	}

	ctx := context.TODO()
	var user models.User
	var err error

	// Resolve identifier (email or EID)
	if strings.Contains(input.Identifier, "@") {
		err = uc.UserCollection.FindOne(ctx, bson.M{
			"email": strings.TrimSpace(strings.ToLower(input.Identifier)),
		}).Decode(&user)
	} else {
		err = uc.UserCollection.FindOne(ctx, bson.M{
			"eid": input.Identifier,
		}).Decode(&user)
	}

	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"valid": false})
		return
	}

	// Compare password
	if bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(input.Password)) != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"valid": false})
		return
	}

	// Everything OK
	c.JSON(http.StatusOK, gin.H{
		"valid": true,
	})
}

// func (uc *UserController) SendCodeSignIn(c *gin.Context) {
// 	var input struct {
// 		Identifier string `json:"identifier"`
// 	}

// 	if err := c.BindJSON(&input); err != nil || input.Identifier == "" {
// 		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input"})
// 		return
// 	}

// 	ctx := context.TODO()
// 	now := time.Now()
// 	code := utils.GenerateCode(6)
// 	var user models.User
// 	var email string

// 	if strings.Contains(input.Identifier, "@") {
// 		email = strings.TrimSpace(strings.ToLower(input.Identifier))
// 		err := uc.UserCollection.FindOne(ctx, bson.M{"email": email}).Decode(&user)
// 		if err != nil {
// 			c.JSON(http.StatusBadRequest, gin.H{"error": "Email not registered"})
// 			return
// 		}
// 	} else {
// 		err := uc.UserCollection.FindOne(ctx, bson.M{"eid": input.Identifier}).Decode(&user)
// 		if err != nil {
// 			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid EID"})
// 			return
// 		}
// 		email = user.Email
// 	}

// 	// Save or update code in EmailCodeCollection (NOT user collection)
// 	_, _ = uc.CodeController.EmailCodeCollection.UpdateOne(
// 		ctx,
// 		bson.M{"email": email},
// 		bson.M{
// 			"$set": bson.M{
// 				"email":    email,
// 				"code":     code,
// 				"sentAt":   now,
// 				"isActive": true,
// 			},
// 		},
// 		options.Update().SetUpsert(true),
// 	)

// 	errMail := services.SendEmail(
// 		email,
// 		"Your Verification Code",
// 		fmt.Sprintf("<h3>Your verification code is: <b>%s</b></h3>", code),
// 	)
// 	if errMail != nil {
// 		log.Println("Failed to send email:", errMail)
// 		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to send email"})
// 		return
// 	}

// 	log.Printf("Verification code sent to %s: %s", email, code)
// 	c.JSON(http.StatusOK, gin.H{"message": "Verification code sent"})
// }

func (uc *UserController) RegisterPin(c *gin.Context) {
	var input struct {
		Pin string `json:"pin"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input"})
		return
	}

	if len(input.Pin) != 4 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "PIN must be 4 digits"})
		return
	}

	email, exists := c.Get("email")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}

	hashedPin, err := bcrypt.GenerateFromPassword([]byte(input.Pin), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to hash PIN"})
		return
	}

	_, err = uc.UserCollection.UpdateOne(
		c,
		bson.M{"email": email},
		bson.M{"$set": bson.M{"pin": string(hashedPin)}},
	)

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to register PIN"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "PIN registered successfully"})
}

func (uc *UserController) ValidatePin(c *gin.Context) {

	var input struct {
		Pin string `json:"pin"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input"})
		return
	}

	if len(input.Pin) != 4 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "PIN must be 4 digits"})
		return
	}

	emailRaw, exists := c.Get("email")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}
	email := emailRaw.(string)

	var user struct {
		Pin string `bson:"pin"`
	}

	if err := uc.UserCollection.FindOne(c, bson.M{"email": email}).Decode(&user); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "User not found"})
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.Pin), []byte(input.Pin)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid PIN"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "PIN validated successfully"})
}

func (uc *UserController) RegisterPattern(c *gin.Context) {
	// Input struct
	var input struct {
		Pattern []int `json:"pattern"`
	}

	// Bind JSON
	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input"})
		return
	}

	// Validate pattern length
	if len(input.Pattern) < 4 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Pattern must have at least 4 dots"})
		return
	}

	// Get email from context (middleware should set this)
	emailRaw, exists := c.Get("email")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}
	email, ok := emailRaw.(string)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Invalid email in context"})
		return
	}

	// Convert pattern to string like "1-2-3-4"
	dotStrings := make([]string, len(input.Pattern))
	for i, dot := range input.Pattern {
		dotStrings[i] = fmt.Sprintf("%d", dot+1) // +1 if Flutter indexes start from 0
	}
	patternStr := strings.Join(dotStrings, "-")

	// Hash pattern
	hashedPattern, err := bcrypt.GenerateFromPassword([]byte(patternStr), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to hash pattern"})
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	filter := bson.M{"email": email}
	update := bson.M{"$set": bson.M{"patternHash": string(hashedPattern)}}

	result, err := uc.UserCollection.UpdateOne(ctx, filter, update)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save pattern"})
		return
	}

	if result.MatchedCount == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "User not found"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Pattern registered successfully"})
}

func (uc *UserController) ValidatePattern(c *gin.Context) {
	// Input struct
	var input struct {
		Pattern []int `json:"pattern"`
	}

	if err := c.ShouldBindJSON(&input); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input"})
		return
	}

	if len(input.Pattern) < 4 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Pattern too short"})
		return
	}

	// Get email from token
	emailRaw, exists := c.Get("email")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Unauthorized"})
		return
	}
	email := emailRaw.(string)

	// Convert pattern to a string like "1-5-9-8"
	dotStrings := make([]string, len(input.Pattern))
	for i, dot := range input.Pattern {
		dotStrings[i] = fmt.Sprintf("%d", dot+1)
	}
	patternStr := strings.Join(dotStrings, "-")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Fetch user
	var user models.User
	err := uc.UserCollection.FindOne(ctx, bson.M{"email": email}).Decode(&user)
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid user"})
		return
	}

	if user.PatternHash == "" {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "Pattern not registered"})
		return
	}

	// Compare hash
	err = bcrypt.CompareHashAndPassword([]byte(user.PatternHash), []byte(patternStr))
	if err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"valid": false, "error": "Pattern does not match"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"valid": true})
}

func (uc *UserController) Logout(c *gin.Context) {
	c.JSON(http.StatusOK, gin.H{"message": "Logged out successfully"})
}

func (uc *UserController) ResetPassword(c *gin.Context) {
	var req struct {
		Identifier      string `json:"identifier"` // Email or EID
		Code            string `json:"code"`       // Email code or TOTP
		NewPassword     string `json:"newPassword"`
		ConfirmPassword string `json:"confirmPassword"`
		Method          string `json:"method"` // "email" or "auth"
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid input"})
		return
	}

	if req.NewPassword != req.ConfirmPassword {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Passwords do not match"})
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Resolve user
	var user models.User
	var email string
	if strings.Contains(req.Identifier, "@") {
		email = strings.TrimSpace(strings.ToLower(req.Identifier))
		if err := uc.UserCollection.FindOne(ctx, bson.M{"email": email}).Decode(&user); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Email not registered"})
			return
		}
	} else {
		if err := uc.UserCollection.FindOne(ctx, bson.M{"eid": req.Identifier}).Decode(&user); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid EID"})
			return
		}
		email = user.Email
	}

	// Verify code
	switch strings.ToLower(req.Method) {
	case "auth":
		if user.TwoFASecret == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "User has no authenticator setup"})
			return
		}
		if !totp.Validate(req.Code, user.TwoFASecret) {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid authenticator code"})
			return
		}

	case "email":
		var codeDoc models.EmailCode
		err := uc.CodeController.EmailCodeCollection.FindOne(ctx, bson.M{
			"email":    email,
			"code":     req.Code,
			"isActive": true,
		}).Decode(&codeDoc)
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid or expired code"})
			return
		}

		// Expiry check
		if time.Since(codeDoc.SentAt) > 5*time.Minute {
			_, _ = uc.CodeController.EmailCodeCollection.DeleteOne(ctx, bson.M{"_id": codeDoc.ID})
			c.JSON(http.StatusBadRequest, gin.H{"error": "Code expired"})
			return
		}

		// ✅ Defer deactivation/deletion until after password reset
		defer func() {
			_, _ = uc.CodeController.EmailCodeCollection.DeleteOne(ctx, bson.M{"_id": codeDoc.ID})
		}()

	default:
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid method"})
		return
	}

	// Hash password
	hashed, err := bcrypt.GenerateFromPassword([]byte(req.NewPassword), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Password encryption failed"})
		return
	}

	// Update password
	_, err = uc.UserCollection.UpdateOne(ctx,
		bson.M{"email": email},
		bson.M{"$set": bson.M{"password": string(hashed)}},
	)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to update password"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "Password reset successful"})
}

func (uc *UserController) CheckEID(c *gin.Context) {
	var input struct {
		EID string `json:"eid"`
	}

	if err := c.ShouldBindJSON(&input); err != nil || input.EID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "EID is required"})
		return
	}

	eid := strings.ToLower(strings.TrimSpace(input.EID))

	var user models.User
	err := uc.UserCollection.FindOne(context.TODO(), bson.M{"eid": eid}).Decode(&user)
	if err == mongo.ErrNoDocuments {
		// EID does NOT exist → available
		c.JSON(http.StatusOK, gin.H{"available": true})
		return
	} else if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Database error"})
		return
	}

	// EID exists → not available
	c.JSON(http.StatusOK, gin.H{"available": false})
}
