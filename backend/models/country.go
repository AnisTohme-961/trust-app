package models

type Country struct {
	ID   string `bson:"_id"`
	Name string `bson:"name"`
	Flag string `bson:"flag"`
}
