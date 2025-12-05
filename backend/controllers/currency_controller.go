package controllers

import (
	"context"
	"net/http"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
)

type CurrencyController struct {
	Collection *mongo.Collection
}

func (cc *CurrencyController) GetCurrencies(c *gin.Context) {
	ctx := context.TODO()
	cursor, err := cc.Collection.Find(ctx, bson.M{})
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}
	defer cursor.Close(ctx)

	var currencies []bson.M
	if err := cursor.All(ctx, &currencies); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, currencies)
}
