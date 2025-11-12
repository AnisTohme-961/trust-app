package main

import (
	"context"
	"log"
	"os"
	"time"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"

	"flutter_project_backend/controllers"
	"flutter_project_backend/routes"
	"flutter_project_backend/seed"
)

func main() {

	if err := godotenv.Load("./.env"); err != nil {
		log.Println("No .env file found, using system environment variables")
	}

	mongoURI := os.Getenv("MONGO_URI")
	mongoDB := os.Getenv("MONGO_DB")
	if mongoURI == "" || mongoDB == "" {
		log.Fatal("MONGO_URI and MONGO_DB must be set in environment variables")
	}

	clientOptions := options.Client().ApplyURI(mongoURI)
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	client, err := mongo.Connect(ctx, clientOptions)
	if err != nil {
		log.Fatal("MongoDB connection error:", err)
	}

	db := client.Database(mongoDB)

	userCollection := db.Collection("users")
	languageCollection := db.Collection("languages")
	countryCollection := db.Collection("countries")
	emailCodeCollection := db.Collection("email_codes")

	controllers.SetupEmailCodeTTL(emailCodeCollection)

	go controllers.CleanupExpiredCodes(emailCodeCollection)

	if err := seed.SeedLanguages(languageCollection); err != nil {
		log.Fatal("Failed to seed languages:", err)
	}

	if err := seed.SeedCountries(countryCollection); err != nil {
		log.Fatal("Failed to seed countries:", err)
	}

	r := gin.Default()

	r.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"*"},
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Accept"},
		AllowCredentials: true,
	}))

	codeController := &controllers.CodeController{
		EmailCodeCollection: emailCodeCollection,
		UserCollection:      userCollection,
	}

	totpController := &controllers.TOTPController{
		UserCollection: userCollection,
	}

	routes.LanguageRoutes(r, languageCollection)
	routes.CountryRoutes(r, countryCollection)
	routes.CodeRoutes(r, codeController)
	routes.TOTPRoutes(r, totpController)
	routes.UserRoutes(r, userCollection, codeController)

	r.Static("/flags", "./flags")
	r.Static("/flags2", "./flags2")

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Println("Server running on port", port)
	if err := r.Run("0.0.0.0:" + port); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}
