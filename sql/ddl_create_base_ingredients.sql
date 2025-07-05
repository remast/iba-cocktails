-- ddl_create_base_ingredients.sql – Base ingredients catalog for IBA cocktails DB
-- -----------------------------------------------------------------------------
-- Creates a catalogue of standalone ingredients (one row per ingredient) and
-- bulk-inserts immutable reference data extracted from ingredients.json.
--
-- Prerequisites:
--   • `slugify(text)` function (defined in ddl_create_cocktails.sql)
--   • `pgcrypto` extension for gen_random_uuid()
--
-- Usage:
--   psql -f ddl_create_base_ingredients.sql
-- -----------------------------------------------------------------------------

-----------------------------
-- 1. Table                --
-----------------------------

CREATE TABLE IF NOT EXISTS base_ingredients (
    id    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    slug  text UNIQUE NOT NULL,
    name  text NOT NULL,
    abv   numeric,   -- Alcohol by volume percentage (0-100)
    taste text       -- e.g. sweet, sour, bitter, salty
);

-----------------------------
-- 2. Seed data           --
-----------------------------

INSERT INTO base_ingredients (slug, name, abv, taste) VALUES
    (slugify('Absinthe'), 'Absinthe', 40, NULL),
    (slugify('Aperol'), 'Aperol', 11, 'bitter'),
    (slugify('Apricot brandy'), 'Apricot brandy', 40, NULL),
    (slugify('Blackberry liqueur'), 'Blackberry liqueur', 40, NULL),
    (slugify('Cachaca'), 'Cachaca', 40, NULL),
    (slugify('Calvados'), 'Calvados', 40, NULL),
    (slugify('Campari'), 'Campari', 25, NULL),
    (slugify('Champagne'), 'Champagne', 12, NULL),
    (slugify('Cherry liqueur'), 'Cherry liqueur', 30, NULL),
    (slugify('Coconut milk'), 'Coconut milk', 0, 'sweet'),
    (slugify('Coffee liqueur'), 'Coffee liqueur', 20, 'bitter'),
    (slugify('Cognac'), 'Cognac', 40, NULL),
    (slugify('Cola'), 'Cola', 0, 'bitter'),
    (slugify('Cranberry juice'), 'Cranberry juice', 0, 'sour'),
    (slugify('Cream'), 'Cream', 0, 'sweet'),
    (slugify('Cream liqueur'), 'Cream liqueur', 20, NULL),
    (slugify('Créme liqueur'), 'Créme liqueur', 20, NULL),
    (slugify('Dark rum'), 'Dark rum', 40, NULL),
    (slugify('DiSaronno'), 'DiSaronno', 28, NULL),
    (slugify('DOM Bénédictine'), 'DOM Bénédictine', 40, NULL),
    (slugify('Drambuie'), 'Drambuie', 40, NULL),
    (slugify('Dry White Wine'), 'Dry White Wine', 12, NULL),
    (slugify('Egg yolk'), 'Egg yolk', 0, NULL),
    (slugify('Galliano'), 'Galliano', 30, 'sweet'),
    (slugify('Gin'), 'Gin', 40, NULL),
    (slugify('Ginger Ale'), 'Ginger Ale', 0, NULL),
    (slugify('Ginger beer'), 'Ginger beer', 5, 'sweet'),
    (slugify('Grapefruit juice'), 'Grapefruit juice', 0, 'sour'),
    (slugify('Hot coffee'), 'Hot coffee', 0, 'bitter'),
    (slugify('Kirsch'), 'Kirsch', 40, NULL),
    (slugify('Lemon juice'), 'Lemon juice', 0, 'sour'),
    (slugify('Lillet Blonde'), 'Lillet Blonde', 15, NULL),
    (slugify('Lime juice'), 'Lime juice', 0, 'sour'),
    (slugify('Olive juice'), 'Olive juice', 0, 'sour'),
    (slugify('Orange Bitters'), 'Orange Bitters', 40, NULL),
    (slugify('Orange juice'), 'Orange juice', 0, 'sweet'),
    (slugify('Peach puree'), 'Peach puree', 0, 'sweet'),
    (slugify('Peach schnapps'), 'Peach schnapps', 40, 'sweet'),
    (slugify('Pineapple juice'), 'Pineapple juice', 0, 'sweet'),
    (slugify('Pisco'), 'Pisco', 40, NULL),
    (slugify('Prosecco'), 'Prosecco', 12, NULL),
    (slugify('Raspberry liqueur'), 'Raspberry liqueur', 20, 'sweet'),
    (slugify('Red Port'), 'Red Port', 20, NULL),
    (slugify('Soda water'), 'Soda water', 0, NULL),
    (slugify('Syrup'), 'Syrup', 0, 'sweet'),
    (slugify('Tequila'), 'Tequila', 40, NULL),
    (slugify('Tomato juice'), 'Tomato juice', 0, 'salty'),
    (slugify('Triple Sec'), 'Triple Sec', 40, 'sweet'),
    (slugify('Vermouth'), 'Vermouth', 17, NULL),
    (slugify('Vodka'), 'Vodka', 40, NULL),
    (slugify('Whiskey'), 'Whiskey', 40, NULL),
    (slugify('White rum'), 'White rum', 40, NULL);

-----------------------------
-- 3. Indexes              --
-----------------------------

CREATE INDEX IF NOT EXISTS idx_base_ing_slug ON base_ingredients(slug); 