package routes

import (
	"flutter_project_backend/controllers"

	"github.com/gin-gonic/gin"
)

func CurrencyRoutes(r *gin.Engine, cc *controllers.CurrencyController) {
	r.GET("/currencies", cc.GetCurrencies)
}
