package routes

import (
	"flutter_project_backend/controllers"

	"github.com/gin-gonic/gin"
)

func CodeRoutes(r *gin.Engine, controller *controllers.CodeController) {
	r.POST("/get-code", controller.GetCode)
	r.POST("/verify-code", controller.VerifyCode)
	r.POST("/get-code-sign-in", controller.GetCodeSignIn)
	r.POST("/verify-code-sign-in", controller.VerifyCodeSignIn)
	// Forgot Password Routes
	r.POST("/send-reset-code", controller.SendResetCode)
	r.POST("/verify-reset-code", controller.VerifyResetCode)
	r.POST("/send-eid-code", controller.GetEIDCode)
	r.POST("/verify-eid-code", controller.VerifyEIDCode)
	r.POST("/forgot-eid", controller.ForgotEID)

}

// totp routes

func TOTPRoutes(r *gin.Engine, controller *controllers.TOTPController) {
	r.POST("/generate-totp", controller.GenerateTOTP)
	r.POST("/verify-totp", controller.VerifyTOTP)
}
