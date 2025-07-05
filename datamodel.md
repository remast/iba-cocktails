# Database Tables Summary

This is a **cocktail recipe database** with 3 main tables containing information about cocktails, their ingredients, and base ingredient definitions.

## Tables Overview

### 1. `base_ingredients` (52 records)
**Purpose**: Master list of all available ingredients that can be used in cocktails

**Key Fields**:
- `id` (UUID) - Primary key
- `slug` (text) - URL-friendly identifier, unique
- `name` (text) - Display name (e.g., "Absinthe", "Aperol", "Apricot brandy")
- `abv` (numeric) - Alcohol by volume percentage
- `taste` (text) - Flavor profile (e.g., "bitter")

**Sample Data**:
- Absinthe (40% ABV)
- Aperol (11% ABV, bitter taste)
- Apricot brandy (40% ABV)
- Blackberry liqueur (40% ABV)
- Cachaca (40% ABV)

### 2. `cocktails` (55 records)
**Purpose**: Master list of cocktail recipes with basic information

**Key Fields**:
- `id` (UUID) - Primary key
- `slug` (text) - URL-friendly identifier, unique
- `name` (text) - Cocktail name (e.g., "Negroni", "Old Fashioned", "Mojito")
- `glass` (text) - Glassware type (e.g., "old-fashioned", "martini", "collins")
- `category` (text) - Cocktail category (e.g., "Before Dinner Cocktail", "Longdrink")
- `garnish` (text) - Garnish instructions
- `preparation` (text) - Preparation method
- `image_url` (text) - Image reference

**Sample Data**:
- Negroni (old-fashioned glass, Before Dinner Cocktail)
- Old Fashioned (old-fashioned glass, Before Dinner Cocktail)
- Mojito (collins glass, Longdrink)
- Horse's Neck (highball glass, Longdrink)

### 3. `ingredients` (163 records)
**Purpose**: Junction table linking cocktails to their specific ingredients with quantities

**Key Fields**:
- `id` (UUID) - Primary key
- `cocktail_id` (UUID) - Foreign key to cocktails table
- `base_ingredient_id` (UUID) - Foreign key to base_ingredients table
- `position` (smallint) - Order of ingredient in recipe
- `amount` (numeric) - Quantity needed
- `unit` (text) - Unit of measurement (e.g., "ml", "oz", "dash")
- `label` (text) - Custom label for the ingredient
- `special` (text) - Special preparation notes

## Database Relationships

```
cocktails (1) ←→ (many) ingredients (many) ←→ (1) base_ingredients
```

- Each cocktail can have multiple ingredients
- Each ingredient record links a specific cocktail to a base ingredient
- Ingredients are ordered by position within each cocktail recipe
- The database enforces referential integrity with foreign key constraints

## Key Features

- **Unique slugs** for SEO-friendly URLs on both cocktails and base ingredients
- **Proper indexing** on frequently queried fields (slugs, foreign keys)
- **Flexible ingredient system** allowing custom amounts, units, and special instructions
- **Comprehensive cocktail metadata** including glassware, categories, and preparation details
- **UUID primary keys** for scalability and avoiding ID conflicts


## Queries

```sql
SELECT JSON_AGG(
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
       ) AS cocktails_json
FROM (
         SELECT
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
         GROUP BY c.id, c.slug, c.name, c.glass, c.category, c.garnish, c.preparation, c.image_url
     ) AS cocktail_data;
```