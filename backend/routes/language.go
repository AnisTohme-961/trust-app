package routes

import (
	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/mongo"

	"flutter_project_backend/controllers"
)

// routes/language.go
func LanguageRoutes(r *gin.Engine, languageCollection *mongo.Collection) {
	r.GET("/languages", func(c *gin.Context) {
		controllers.GetLanguages(c, languageCollection)
	})
}
