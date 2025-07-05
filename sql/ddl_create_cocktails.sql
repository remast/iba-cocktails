-- ddl_create_cocktails.sql – Schema for IBA cocktails database
-- -------------------------------------------------------------
-- This file creates all objects required to store IBA cocktails
-- and their ingredients in PostgreSQL.  Execute it once on an
-- empty database (psql -f ddl_create_cocktails.sql).
--
-- Requirements
--   • PostgreSQL 12+
--   • Extensions: pgcrypto (for gen_random_uuid) and unaccent
-- -------------------------------------------------------------

-----------------------------
-- 1. Extensions & helpers  --
-----------------------------

-- UUID generator
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
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
-- 2. Main tables          --
-----------------------------

-- Cocktails / recipes
CREATE TABLE IF NOT EXISTS cocktails (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    slug        text UNIQUE     NOT NULL,
    name        text            NOT NULL,
    glass       text,
    category    text,
    garnish     text,
    preparation text,
    image_url   text
);

-- Ingredients belonging to a cocktail
CREATE TABLE IF NOT EXISTS ingredients (
    id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    cocktail_id  uuid NOT NULL REFERENCES cocktails(id) ON DELETE CASCADE,
    position     smallint,     -- keeps original ordering
    base_ingredient_id uuid NOT NULL REFERENCES base_ingredients(id),
    amount       numeric,
    unit         text,
    label        text,
    special      text,
    UNIQUE(cocktail_id, position)
);

-----------------------------
-- 3. Indexes              --
-----------------------------

CREATE INDEX IF NOT EXISTS idx_cocktails_slug     ON cocktails(slug);
CREATE INDEX IF NOT EXISTS idx_ingredients_parent ON ingredients(cocktail_id);
CREATE INDEX IF NOT EXISTS idx_ingredients_base   ON ingredients(base_ingredient_id);

-- end 