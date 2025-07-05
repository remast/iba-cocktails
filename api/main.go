package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

// Shared inner query to build cocktail rows with aggregated ingredients.
const cocktailRowsQuery = `SELECT
    c.id,
    c.slug,
    c.name,
    c.glass,
    c.category,
    c.garnish,
    c.preparation,
    c.image_url,
    JSON_AGG(
        JSON_BUILD_OBJECT(
            'position', i.position,
            'amount', i.amount,
            'unit', i.unit,
            'label', i.label,
            'special', i.special,
            'base_ingredient', JSON_BUILD_OBJECT(
                'id', bi.id,
                'slug', bi.slug,
                'name', bi.name,
                'abv', bi.abv,
                'taste', bi.taste
            )
        ) ORDER BY i.position
    ) AS ingredients
FROM cocktails c
LEFT JOIN ingredients i ON c.id = i.cocktail_id
LEFT JOIN base_ingredients bi ON i.base_ingredient_id = bi.id
GROUP BY c.id, c.slug, c.name, c.glass, c.category, c.garnish, c.preparation, c.image_url`

// Query for all cocktails ordered by name (as JSON array).
const cocktailsQuery = `SELECT COALESCE(JSON_AGG(
           JSON_BUILD_OBJECT(
               'id', cocktail_data.id,
               'slug', cocktail_data.slug,
               'name', cocktail_data.name,
               'glass', cocktail_data.glass,
               'category', cocktail_data.category,
               'garnish', cocktail_data.garnish,
               'preparation', cocktail_data.preparation,
               'image_url', cocktail_data.image_url,
               'ingredients', cocktail_data.ingredients
           ) ORDER BY cocktail_data.name
       ), '[]'::json) AS cocktails_json
FROM (
    ` + cocktailRowsQuery + `
) AS cocktail_data;`

// Query for a single random cocktail (as JSON object).
const randomCocktailQuery = `SELECT COALESCE(
           JSON_BUILD_OBJECT(
               'id', cocktail_data.id,
               'slug', cocktail_data.slug,
               'name', cocktail_data.name,
               'glass', cocktail_data.glass,
               'category', cocktail_data.category,
               'garnish', cocktail_data.garnish,
               'preparation', cocktail_data.preparation,
               'image_url', cocktail_data.image_url,
               'ingredients', cocktail_data.ingredients
           ), '{}'::json) AS cocktail_json
FROM (
    ` + cocktailRowsQuery + `
    ORDER BY RANDOM()
    LIMIT 1
) AS cocktail_data;`

func main() {
	connStr := os.Getenv("DATABASE_URL")
	if connStr == "" {
		log.Fatal("environment variable DATABASE_URL is not set")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	pool, err := pgxpool.New(ctx, connStr)
	if err != nil {
		log.Fatalf("unable to create connection pool: %v", err)
	}
	defer pool.Close()

	http.HandleFunc("/api/cocktails", cocktailsHandler(pool))
	http.HandleFunc("/api/cocktails/random", randomCocktailHandler(pool))

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Server listening on :%s", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatalf("server error: %v", err)
	}
}

func cocktailsHandler(pool *pgxpool.Pool) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
			return
		}

		ctx, cancel := context.WithTimeout(r.Context(), 5*time.Second)
		defer cancel()

		var jsonData []byte
		err := pool.QueryRow(ctx, cocktailsQuery).Scan(&jsonData)
		if err != nil {
			log.Printf("query error: %v", err)
			http.Error(w, "internal server error", http.StatusInternalServerError)
			return
		}

		w.Header().Set("Content-Type", "application/json")
		w.Write(jsonData)
	}
}

func randomCocktailHandler(pool *pgxpool.Pool) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
			return
		}

		ctx, cancel := context.WithTimeout(r.Context(), 5*time.Second)
		defer cancel()

		var jsonData []byte
		err := pool.QueryRow(ctx, randomCocktailQuery).Scan(&jsonData)
		if err != nil {
			log.Printf("query error: %v", err)
			http.Error(w, "internal server error", http.StatusInternalServerError)
			return
		}

		w.Header().Set("Content-Type", "application/json")
		w.Write(jsonData)
	}
}
