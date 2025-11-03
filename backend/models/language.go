package models

type Language struct {
	ID         string `bson:"_id"`
	Name       string `bson:"name"`
	NativeName string `bson:"nativeName"`
	Flag       string `bson:"flag"`
}
