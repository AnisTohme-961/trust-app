package controllers

import (
	"context"
	"fmt"
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

	type SimpleCurrency struct {
		Symbol string  `json:"symbol"`
		Price  float64 `json:"price"`
	}

	var currencies []SimpleCurrency

	for cursor.Next(ctx) {
		var cur struct {
			Symbol string  `bson:"symbol"`
			Price  float64 `bson:"price"`
		}
		if err := cursor.Decode(&cur); err != nil {
			fmt.Println("Decode error:", err)
			continue
		}
		currencies = append(currencies, SimpleCurrency{
			Symbol: cur.Symbol,
			Price:  cur.Price,
		})
	}

	c.JSON(http.StatusOK, currencies)
}
