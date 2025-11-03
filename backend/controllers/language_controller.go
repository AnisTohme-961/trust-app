package controllers

import (
	"context"
	"net/http"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"

	"flutter_project_backend/models"
)

func GetLanguages(c *gin.Context, collection *mongo.Collection) {
	ctx := context.Background()
	cur, err := collection.Find(ctx, bson.M{})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer cur.Close(ctx)

	var languages []models.Language
	for cur.Next(ctx) {
		var lang models.Language
		if err := cur.Decode(&lang); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		languages = append(languages, lang)
	}

	if err := cur.Err(); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, languages)
}

func GetTranslations(c *gin.Context, collection *mongo.Collection) {
	lang := c.Param("lang")
	ctx := context.Background()

	cur, err := collection.Find(ctx, bson.M{})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer cur.Close(ctx)

	result := make(map[string]string)
	for cur.Next(ctx) {
		var t models.Translation
		if err := cur.Decode(&t); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		if val, ok := t.Translations[lang]; ok {
			result[t.Key] = val
		}
	}

	if err := cur.Err(); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, result)
}
