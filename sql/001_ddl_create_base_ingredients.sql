-- ddl_create_base_ingredients.sql – Base ingredients catalog for IBA cocktails DB
-- -----------------------------------------------------------------------------
-- Creates a catalogue of standalone ingredients (one row per ingredient) and
-- bulk-inserts immutable reference data extracted from ingredients.json.
--
-- Usage:
--   psql -f ddl_create_base_ingredients.sql
-- -----------------------------------------------------------------------------

-- Remove diacritics for clean slugs
CREATE EXTENSION IF NOT EXISTS "unaccent";

-- Utility function: slugify(text) → text
-- Turns arbitrary strings into ASCII-only, lowercase, dash-separated slugs
CREATE OR REPLACE FUNCTION slugify(in_str text)
RETURNS text AS $$
    SELECT regexp_replace(
             regexp_replace(
               lower(unaccent(in_str)),          -- 1) strip accents + lowercase
               '\s+', '-', 'g'                  -- 2) collapse whitespace → ―
             ),
             '[^a-z0-9\-]', '', 'g'             -- 3) remove non url-safe chars
           );
$$ LANGUAGE sql IMMUTABLE STRICT;


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

INSERT INTO base_ingredients (id, slug, name, abv, taste) VALUES
    ('00000000-0000-0000-0000-000000000001', slugify('Absinthe'), 'Absinthe', 40, NULL),
    ('00000000-0000-0000-0000-000000000002', slugify('Aperol'), 'Aperol', 11, 'bitter'),
    ('00000000-0000-0000-0000-000000000003', slugify('Apricot brandy'), 'Apricot brandy', 40, NULL),
    ('00000000-0000-0000-0000-000000000004', slugify('Blackberry liqueur'), 'Blackberry liqueur', 40, NULL),
    ('00000000-0000-0000-0000-000000000005', slugify('Cachaca'), 'Cachaca', 40, NULL),
    ('00000000-0000-0000-0000-000000000006', slugify('Calvados'), 'Calvados', 40, NULL),
    ('00000000-0000-0000-0000-000000000007', slugify('Campari'), 'Campari', 25, NULL),
    ('00000000-0000-0000-0000-000000000008', slugify('Champagne'), 'Champagne', 12, NULL),
    ('00000000-0000-0000-0000-000000000009', slugify('Cherry liqueur'), 'Cherry liqueur', 30, NULL),
    ('00000000-0000-0000-0000-000000000010', slugify('Coconut milk'), 'Coconut milk', 0, 'sweet'),
    ('00000000-0000-0000-0000-000000000011', slugify('Coffee liqueur'), 'Coffee liqueur', 20, 'bitter'),
    ('00000000-0000-0000-0000-000000000012', slugify('Cognac'), 'Cognac', 40, NULL),
    ('00000000-0000-0000-0000-000000000013', slugify('Cola'), 'Cola', 0, 'bitter'),
    ('00000000-0000-0000-0000-000000000014', slugify('Cranberry juice'), 'Cranberry juice', 0, 'sour'),
    ('00000000-0000-0000-0000-000000000015', slugify('Cream'), 'Cream', 0, 'sweet'),
    ('00000000-0000-0000-0000-000000000016', slugify('Cream liqueur'), 'Cream liqueur', 20, NULL),
    ('00000000-0000-0000-0000-000000000017', slugify('Créme liqueur'), 'Créme liqueur', 20, NULL),
    ('00000000-0000-0000-0000-000000000018', slugify('Dark rum'), 'Dark rum', 40, NULL),
    ('00000000-0000-0000-0000-000000000019', slugify('DiSaronno'), 'DiSaronno', 28, NULL),
    ('00000000-0000-0000-0000-000000000020', slugify('DOM Bénédictine'), 'DOM Bénédictine', 40, NULL),
    ('00000000-0000-0000-0000-000000000021', slugify('Drambuie'), 'Drambuie', 40, NULL),
    ('00000000-0000-0000-0000-000000000022', slugify('Dry White Wine'), 'Dry White Wine', 12, NULL),
    ('00000000-0000-0000-0000-000000000023', slugify('Egg yolk'), 'Egg yolk', 0, NULL),
    ('00000000-0000-0000-0000-000000000024', slugify('Galliano'), 'Galliano', 30, 'sweet'),
    ('00000000-0000-0000-0000-000000000025', slugify('Gin'), 'Gin', 40, NULL),
    ('00000000-0000-0000-0000-000000000026', slugify('Ginger Ale'), 'Ginger Ale', 0, NULL),
    ('00000000-0000-0000-0000-000000000027', slugify('Ginger beer'), 'Ginger beer', 5, 'sweet'),
    ('00000000-0000-0000-0000-000000000028', slugify('Grapefruit juice'), 'Grapefruit juice', 0, 'sour'),
    ('00000000-0000-0000-0000-000000000029', slugify('Hot coffee'), 'Hot coffee', 0, 'bitter'),
    ('00000000-0000-0000-0000-000000000030', slugify('Kirsch'), 'Kirsch', 40, NULL),
    ('00000000-0000-0000-0000-000000000031', slugify('Lemon juice'), 'Lemon juice', 0, 'sour'),
    ('00000000-0000-0000-0000-000000000032', slugify('Lillet Blonde'), 'Lillet Blonde', 15, NULL),
    ('00000000-0000-0000-0000-000000000033', slugify('Lime juice'), 'Lime juice', 0, 'sour'),
    ('00000000-0000-0000-0000-000000000034', slugify('Olive juice'), 'Olive juice', 0, 'sour'),
    ('00000000-0000-0000-0000-000000000035', slugify('Orange Bitters'), 'Orange Bitters', 40, NULL),
    ('00000000-0000-0000-0000-000000000036', slugify('Orange juice'), 'Orange juice', 0, 'sweet'),
    ('00000000-0000-0000-0000-000000000037', slugify('Peach puree'), 'Peach puree', 0, 'sweet'),
    ('00000000-0000-0000-0000-000000000038', slugify('Peach schnapps'), 'Peach schnapps', 40, 'sweet'),
    ('00000000-0000-0000-0000-000000000039', slugify('Pineapple juice'), 'Pineapple juice', 0, 'sweet'),
    ('00000000-0000-0000-0000-000000000040', slugify('Pisco'), 'Pisco', 40, NULL),
    ('00000000-0000-0000-0000-000000000041', slugify('Prosecco'), 'Prosecco', 12, NULL),
    ('00000000-0000-0000-0000-000000000042', slugify('Raspberry liqueur'), 'Raspberry liqueur', 20, 'sweet'),
    ('00000000-0000-0000-0000-000000000043', slugify('Red Port'), 'Red Port', 20, NULL),
    ('00000000-0000-0000-0000-000000000044', slugify('Soda water'), 'Soda water', 0, NULL),
    ('00000000-0000-0000-0000-000000000045', slugify('Syrup'), 'Syrup', 0, 'sweet'),
    ('00000000-0000-0000-0000-000000000046', slugify('Tequila'), 'Tequila', 40, NULL),
    ('00000000-0000-0000-0000-000000000047', slugify('Tomato juice'), 'Tomato juice', 0, 'salty'),
    ('00000000-0000-0000-0000-000000000048', slugify('Triple Sec'), 'Triple Sec', 40, 'sweet'),
    ('00000000-0000-0000-0000-000000000049', slugify('Vermouth'), 'Vermouth', 17, NULL),
    ('00000000-0000-0000-0000-000000000050', slugify('Vodka'), 'Vodka', 40, NULL),
    ('00000000-0000-0000-0000-000000000051', slugify('Whiskey'), 'Whiskey', 40, NULL),
    ('00000000-0000-0000-0000-000000000052', slugify('White rum'), 'White rum', 40, NULL);

-----------------------------
-- 3. Indexes              --
-----------------------------

CREATE INDEX IF NOT EXISTS idx_base_ing_slug ON base_ingredients(slug); 