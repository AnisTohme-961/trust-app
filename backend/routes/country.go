package routes

import (
	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/mongo"

	"flutter_project_backend/controllers"
)

// routes/country.go
func CountryRoutes(r *gin.Engine, countryCollection *mongo.Collection) {
	r.GET("/countries", func(c *gin.Context) {
		controllers.GetCountries(c, countryCollection)
	})
}
