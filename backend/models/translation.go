package models

type Translation struct {
	Key          string            `bson:"key"`
	Translations map[string]string `bson:"translations"`
}
