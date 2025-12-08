package seed

import (
	"context"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
)

// InsertCurrencies inserts default currencies only if they don't exist
func InsertCurrencies(db *mongo.Database) error {
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	coll := db.Collection("currencies")

	currencies := []bson.M{
		{"code": "ADA", "symbol": "ADA", "name": "Cardano", "symbolapi": "ADAUSDT"},
		{"code": "AVAX", "symbol": "AVAX", "name": "Avalanche", "symbolapi": "AVAXUSDT"},
		{"code": "BCH", "symbol": "BCH", "name": "Bitcoin Cash", "symbolapi": "BCHUSDT"},
		{"code": "BNB", "symbol": "BNB", "name": "Binance Coin", "symbolapi": "BNBUSDT"},
		{"code": "BTC", "symbol": "BTC", "name": "Bitcoin", "symbolapi": "BTCUSDT"},
		{"code": "DOGE", "symbol": "DOGE", "name": "Dogecoin", "symbolapi": "DOGEUSDT"},
		{"code": "ETC", "symbol": "ETC", "name": "Ethereum Classic", "symbolapi": "ETCUSDT"},
		{"code": "ETH", "symbol": "ETH", "name": "Ethereum", "symbolapi": "ETHUSDT"},
		{"code": "EUR", "symbol": "EUR", "name": "Euro", "symbolapi": "EURUSDT"},
		{"code": "LINK", "symbol": "LINK", "name": "Chainlink", "symbolapi": "LINKUSDT"},
		{"code": "LTC", "symbol": "LTC", "name": "Litecoin", "symbolapi": "LTCUSDT"},
		{"code": "PAXG", "symbol": "PAXG", "name": "PAX Gold", "symbolapi": "PAXGUSDT"},
		{"code": "PLA", "symbol": "PLA", "name": "PlayDapp", "symbolapi": "PLAUSDT"},
		{"code": "SOL", "symbol": "SOL", "name": "Solana", "symbolapi": "SOLUSDT"},
		{"code": "TON", "symbol": "TON", "name": "Toncoin", "symbolapi": "TONUSDT"},
		{"code": "TRX", "symbol": "TRX", "name": "Tron", "symbolapi": "TRXUSDT"},
		{"code": "XMR", "symbol": "XMR", "name": "Monero", "symbolapi": "XMRUSDT"},
		{"code": "XRP", "symbol": "XRP", "name": "XRP", "symbolapi": "XRPUSDT"},
		{"code": "ZEC", "symbol": "ZEC", "name": "Zcash", "symbolapi": "ZECUSDT"},
	}

	for _, cur := range currencies {
		filter := bson.M{"symbolapi": cur["symbolapi"]}
		count, err := coll.CountDocuments(ctx, filter)
		if err != nil {
			fmt.Println("Error checking currency:", cur["symbol"], err)
			continue
		}
		if count == 0 {
			_, err := coll.InsertOne(ctx, cur)
			if err != nil {
				fmt.Println("Error inserting currency:", cur["symbol"], err)
				continue
			}
			fmt.Println("Inserted currency:", cur["symbol"])
		}
	}

	fmt.Println("Currency seeding completed")
	return nil
}
