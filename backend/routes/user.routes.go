package routes

import (
	"flutter_project_backend/controllers"

	"flutter_project_backend/middleware"

	"github.com/gin-gonic/gin"

	"go.mongodb.org/mongo-driver/mongo"
)

func UserRoutes(r *gin.Engine, userCollection *mongo.Collection, codeController *controllers.CodeController) {
	controller := controllers.UserController{
		UserCollection: userCollection,
		CodeController: codeController,
	}

	r.POST("/send-code", controller.SendCode)
	r.POST("/register", controller.Register)
	r.POST("/sign-in", controller.SignIn)
	r.POST("/validate-credentials", controller.ValidateCredentials)
	r.POST("/migrate-users-eid", controller.MigrateUsersEID)
	r.POST("/send-code-sign-in", controller.SendCodeSignIn)
	r.POST("/check-eid", controller.CheckEID)
	r.POST("/register-pin", middleware.AuthMiddleware(), controller.RegisterPin)
	r.POST("/register-pattern", middleware.AuthMiddleware(), controller.RegisterPattern)
	r.POST("/logout", middleware.AuthMiddleware(), controller.Logout)
	// Forgot Password Routes
	r.POST("/reset-password", controller.ResetPassword)
}
