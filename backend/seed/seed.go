package seed

import (
	"context"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"

	"flutter_project_backend/models"
)

func SeedLanguages(languageCollection *mongo.Collection) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Check if data already exists
	count, _ := languageCollection.CountDocuments(ctx, bson.M{})
	if count > 0 {
		return nil // already seeded
	}

	languages := []interface{}{
		models.Language{ID: "1", Name: "France", NativeName: "(Français)", Flag: "/assets/images/flags/france.png"},
		models.Language{ID: "2", Name: "Germany", NativeName: "(Deutsch)", Flag: "/assets/images/flags/germany.png"},
		models.Language{ID: "3", Name: "Arabic", NativeName: "(العربية)", Flag: "/assets/images/flags/saudi.png"},
		models.Language{ID: "4", Name: "Italian", NativeName: "(Italiano)", Flag: "/assets/images/flags/italy.png"},
		models.Language{ID: "5", Name: "Spanish", NativeName: "(Espanol)", Flag: "/assets/images/flags/spain.png"},
		models.Language{ID: "6", Name: "Portuguese", NativeName: "(Português)", Flag: "/assets/images/flags/portugal.png"},
		models.Language{ID: "7", Name: "Japanese", NativeName: "(日本語)", Flag: "/assets/images/flags/japan.png"},
		models.Language{ID: "8", Name: "Russian", NativeName: "(Русский)", Flag: "/assets/images/flags/russia.png"},
		models.Language{ID: "9", Name: "Finnish", NativeName: "(Suomi)", Flag: "/assets/images/flags/finland.png"},
	}

	_, err := languageCollection.InsertMany(ctx, languages)
	return err
}

func SeedCountries(countryCollection *mongo.Collection) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	// Check if data already exists
	count, _ := countryCollection.CountDocuments(ctx, bson.M{})
	if count > 0 {
		return nil // already seeded
	}

	countries := []interface{}{
		models.Country{ID: "1", Name: "Trinidad and Tobago", Flag: "/flags2/trinidad-and-tobago-flag-circular-17824.png"},
		models.Country{ID: "2", Name: "Saudi Arabia", Flag: "/flags2/saudi-arabia-circle-rounded-flag-24368.png"},
		models.Country{ID: "3", Name: "Albania", Flag: "/flags2/albania-flag-circular-17866.png"},
		models.Country{ID: "4", Name: "Algeria", Flag: "/flags2/algeria-flag-circular-17772.png"},
		models.Country{ID: "5", Name: "Chile", Flag: "/flags2/chile-flag-circular-17779.png"},
		models.Country{ID: "6", Name: "Denmark", Flag: "/flags2/denmark-flag-circular-17776.png"},
		models.Country{ID: "7", Name: "Honduras", Flag: "/flags2/honduras-flag-circular-17839.png"},
		models.Country{ID: "8", Name: "Ireland", Flag: "/flags2/ireland-flag-circular-17780.png"},
		models.Country{ID: "9", Name: "Jamaica", Flag: "/flags2/jamaica-flag-circular-17804.png"},
		models.Country{ID: "10", Name: "Kazakhstan", Flag: "/flags2/kazakhstan-flag-circular-17856.png"},
		models.Country{ID: "11", Name: "Latvia", Flag: "/flags2/latvia-circular-round-flag-26213.png"},
		models.Country{ID: "12", Name: "Nepal", Flag: "/flags2/nepal-flag-circular-17880.png"},
		models.Country{ID: "13", Name: "Oman", Flag: "/flags2/oman-flag-circle-round-27210.png"},
		models.Country{ID: "14", Name: "Peru", Flag: "/flags2/peru-flag-circular-17794.png"},
		models.Country{ID: "15", Name: "Qatar", Flag: "/flags2/qatar-flag-circular-17881.png"},
	}

	_, err := countryCollection.InsertMany(ctx, countries)
	return err
}
