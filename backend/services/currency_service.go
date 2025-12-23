package services

import (
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"strconv"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

type Currency struct {
	ID        primitive.ObjectID `bson:"_id,omitempty"`
	Code      string             `bson:"code"`
	Symbol    string             `bson:"symbol"`
	Name      string             `bson:"name"`
	SymbolApi string             `bson:"symbolapi"`
	Price     float64            `bson:"price"`
}

type TickerPrice struct {
	Symbol string `json:"symbol"`
	Price  string `json:"price"`
}

func UpdateCurrencyPrices(client *mongo.Client, dbName string) error {
	collection := client.Database(dbName).Collection("currencies")

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	cursor, err := collection.Find(ctx, bson.M{})
	if err != nil {
		return err
	}
	defer cursor.Close(ctx)

	for cursor.Next(ctx) {
		var c Currency
		if err := cursor.Decode(&c); err != nil {
			fmt.Println("Decode error:", err)
			continue
		}

		// Skip if SymbolApi is empty
		if c.SymbolApi == "" {
			fmt.Println("Skipping", c.Code, "because SymbolApi is empty")
			continue
		}

		// Fetch price from Binance
		url := "https://api.binance.com/api/v3/ticker/price?symbol=" + c.SymbolApi
		resp, err := http.Get(url)
		if err != nil {
			fmt.Println("HTTP error for", c.SymbolApi, ":", err)
			continue
		}

		body, err := ioutil.ReadAll(resp.Body)
		resp.Body.Close()
		if err != nil {
			fmt.Println("Read error for", c.SymbolApi, ":", err)
			continue
		}

		var ticker TickerPrice
		if err := json.Unmarshal(body, &ticker); err != nil {
			fmt.Println("JSON parse error for", c.SymbolApi, ":", err, "body:", string(body))
			continue
		}

		price, err := strconv.ParseFloat(ticker.Price, 64)
		if err != nil {
			fmt.Println("Failed to parse price for", c.SymbolApi, ":", ticker.Price, err)
			continue
		}

		// Only update if price is valid (>0)
		if price <= 0 {
			fmt.Println("Skipping update for", c.SymbolApi, "because price is invalid:", price)
			continue
		}

		// Update price in MongoDB
		_, err = collection.UpdateOne(
			ctx,
			bson.M{"symbolapi": c.SymbolApi},
			bson.M{"$set": bson.M{"price": price}},
		)
		if err != nil {
			fmt.Println("MongoDB update error for", c.SymbolApi, ":", err)
			continue
		}

		fmt.Println("Updated:", c.Code, price)
	}

	return nil
}

// func UpdateCurrencyPrices(client *mongo.Client, dbName string) error {
// 	collection := client.Database(dbName).Collection("currencies")

// 	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
// 	defer cancel()

// 	cursor, err := collection.Find(ctx, bson.M{})
// 	if err != nil {
// 		return err
// 	}
// 	defer cursor.Close(ctx)

// 	for cursor.Next(ctx) {
// 		var c Currency
// 		if err := cursor.Decode(&c); err != nil {
// 			fmt.Println("Decode error:", err)
// 			continue
// 		}

// 		// Fetch price from Binance
// 		url := "https://api.binance.com/api/v3/ticker/price?symbol=" + c.SymbolApi
// 		resp, err := http.Get(url)
// 		if err != nil {
// 			fmt.Println("HTTP error for", c.SymbolApi, ":", err)
// 			continue
// 		}

// 		body, err := ioutil.ReadAll(resp.Body)
// 		resp.Body.Close()
// 		if err != nil {
// 			fmt.Println("Read error:", err)
// 			continue
// 		}

// 		var ticker TickerPrice
// 		if err := json.Unmarshal(body, &ticker); err != nil {
// 			fmt.Println("JSON error:", err)
// 			continue
// 		}

// 		price, _ := strconv.ParseFloat(ticker.Price, 64)

// 		// Update price in MongoDB
// 		_, err = collection.UpdateOne(
// 			ctx,
// 			bson.M{"symbolapi": c.SymbolApi},
// 			bson.M{"$set": bson.M{"price": price}},
// 		)
// 		if err != nil {
// 			fmt.Println("Update error:", err)
// 			continue
// 		}

// 		fmt.Println("Updated:", c.Code, price)
// 	}

// 	return nil
// }
