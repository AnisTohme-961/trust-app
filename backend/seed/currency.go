package seed

// imports
import (
	"context"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
)

func InsertCurrencies(db *mongo.Database) error {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	coll := db.Collection("currencies")

	docs := []interface{}{
		bson.M{"code": "ADA", "symbol": "ADA", "name": "Cardano", "symbolapi": "ADAUSDT"},
		bson.M{"code": "AVAX", "symbol": "AVAX", "name": "Avalanche", "symbolapi": "AVAXUSDT"},
		bson.M{"code": "BCH", "symbol": "BCH", "name": "Bitcoin Cash", "symbolapi": "BCHUSDT"},
		bson.M{"code": "BNB", "symbol": "BNB", "name": "Binance Coin", "symbolapi": "BNBUSDT"},
		bson.M{"code": "BTC", "symbol": "BTC", "name": "Bitcoin", "symbolapi": "BTCUSDT"},
		bson.M{"code": "DOGE", "symbol": "DOGE", "name": "Dogecoin", "symbolapi": "DOGEUSDT"},
		bson.M{"code": "ETC", "symbol": "ETC", "name": "Ethereum Classic", "symbolapi": "ETCUSDT"},
		bson.M{"code": "ETH", "symbol": "ETH", "name": "Ethereum", "symbolapi": "ETHUSDT"},
		bson.M{"code": "EUR", "symbol": "EUR", "name": "Euro", "symbolapi": "EURUSDT"},
		bson.M{"code": "LINK", "symbol": "LINK", "name": "Chainlink", "symbolapi": "LINKUSDT"},
		bson.M{"code": "LTC", "symbol": "LTC", "name": "Litecoin", "symbolapi": "LTCUSDT"},
		bson.M{"code": "PAXG", "symbol": "PAXG", "name": "PAX Gold", "symbolapi": "PAXGUSDT"},
		bson.M{"code": "PLA", "symbol": "PLA", "name": "PlayDapp", "symbolapi": "PLAUSDT"},
		bson.M{"code": "SOL", "symbol": "SOL", "name": "Solana", "symbolapi": "SOLUSDT"},
		bson.M{"code": "TON", "symbol": "TON", "name": "Toncoin", "symbolapi": "TONUSDT"},
		bson.M{"code": "TRX", "symbol": "TRX", "name": "Tron", "symbolapi": "TRXUSDT"},
		bson.M{"code": "XMR", "symbol": "XMR", "name": "Monero", "symbolapi": "XMRUSDT"},
		bson.M{"code": "XRP", "symbol": "XRP", "name": "XRP", "symbolapi": "XRPUSDT"},
		bson.M{"code": "ZEC", "symbol": "ZEC", "name": "Zcash", "symbolapi": "ZECUSDT"},
	}

	_, err := coll.InsertMany(ctx, docs)
	if err != nil {
		return err
	}
	fmt.Println("Inserted currencies")
	return nil
}
