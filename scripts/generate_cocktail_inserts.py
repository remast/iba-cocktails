import json
import re
import unicodedata
from pathlib import Path

# -----------------------------------------------------------------------------
# generate_cocktail_inserts.py – Build seed SQL for cocktails & ingredients
# -----------------------------------------------------------------------------
# Reads recipes.json and emits a SQL script (sql/data_insert_cocktails.sql) that
# bulk-inserts all cocktails and their (matched) ingredients using the schema
# defined in:
#   • sql/ddl_create_cocktails.sql          (tables + slugify())
#   • sql/ddl_create_base_ingredients.sql   (seed base ingredients)
#
# Usage:
#   python scripts/generate_cocktail_inserts.py
#
# The generated SQL can be executed via psql:
#   psql -f sql/data_insert_cocktails.sql
# -----------------------------------------------------------------------------

# Paths
ROOT = Path(__file__).resolve().parent.parent
RECIPES_JSON = ROOT / "recipes.json"
BASE_ING_SQL = ROOT / "sql" / "ddl_create_base_ingredients.sql"
OUTPUT_SQL = ROOT / "sql" / "data_insert_cocktails.sql"


# --- helpers -----------------------------------------------------------------

def slugify(text: str) -> str:
    """Mirror the SQL slugify() helper (lowercase, ascii, dash-separated)."""
    # 1) strip accents + lowercase
    txt = unicodedata.normalize("NFKD", text).encode("ascii", "ignore").decode()
    txt = txt.lower()
    # 2) collapse whitespace to single dash
    txt = re.sub(r"\s+", "-", txt)
    # 3) remove non url-safe chars
    txt = re.sub(r"[^a-z0-9\-]", "", txt)
    return txt


def escape_sql(text: str | None) -> str:
    """Return SQL-safe single-quoted literal or NULL."""
    if text is None:
        return "NULL"
    return "'" + text.replace("'", "''") + "'"


# --- Parse base ingredients ---------------------------------------------------

def parse_base_ingredients() -> dict[str, str]:
    """Return mapping slug -> UUID for all base ingredients defined in DDL."""
    # Example line:
    # ('00000000-0000-0000-0000-000000000025', slugify('Gin'), 'Gin', 40, NULL),
    pattern = re.compile(
        r"'([0-9a-fA-F\-]{36})'\s*,\s*slugify\('([^']+)'\)",
        re.IGNORECASE,
    )
    mapping: dict[str, str] = {}
    with BASE_ING_SQL.open("r", encoding="utf-8") as fp:
        for line in fp:
            m = pattern.search(line)
            if m:
                uuid, name = m.groups()
                mapping[slugify(name)] = uuid.lower()
    return mapping


# --- Build SQL ----------------------------------------------------------------

def main():
    # Load data
    recipes = json.loads(RECIPES_JSON.read_text("utf-8"))
    base_map = parse_base_ingredients()
    valid_base_slugs = set(base_map.keys())
    unmatched: dict[str, set[str]] = {}  # ingredient name -> set[cocktail names]

    out_lines: list[str] = [
        "-- -------------------------------------------------------------",
        "-- data_insert_cocktails.sql – Seed data for cocktails & ingredients",
        "-- ⚠️  Auto-generated by scripts/generate_cocktail_inserts.py",
        "--      DO NOT EDIT MANUALLY",
        "-- -------------------------------------------------------------\n",
    ]

    for recipe in recipes:
        name = recipe["name"]
        c_slug = slugify(name)
        glass = recipe.get("glass")
        category = recipe.get("category")
        garnish = recipe.get("garnish")
        prep = recipe.get("preparation")
        image_url = recipe.get("image_url")

        # Comment header
        out_lines.append(f"-- Cocktail: {name}")

        # 1) insert cocktail + capture id
        fields = [
            escape_sql(c_slug),
            escape_sql(name),
            escape_sql(glass),
            escape_sql(category),
            escape_sql(garnish),
            escape_sql(prep),
            escape_sql(image_url),
        ]
        out_lines.append(
            "WITH new_cocktail AS (\n    "
            "INSERT INTO cocktails (slug, name, glass, category, garnish, preparation, image_url)\n    "
            f"VALUES ({', '.join(fields)})\n    RETURNING id\n)"
        )

        # 2) insert ingredients
        ing_values: list[str] = []
        for pos, ing in enumerate(recipe.get("ingredients", []), start=1):
            # Only keep entries that map to a base ingredient
            ing_name = ing.get("ingredient")
            if not ing_name:
                continue  # skip 'special' only rows
            ing_slug = slugify(ing_name)
            if ing_slug not in valid_base_slugs:
                # Track missing for reporting
                unmatched.setdefault(ing_name, set()).add(recipe["name"])
                continue  # unknown base ingredient

            amount = ing.get("amount")
            unit = ing.get("unit")
            label = ing.get("label")
            special = ing.get("special")  # rarely present together with ingredient

            base_id = base_map[ing_slug]
            comment = ing_name.replace('*/', '* /')  # guard against premature comment close
            ing_values.append(
                "((SELECT id FROM new_cocktail), {pos}, '{uuid}', {amt}, {unit}, {label}, {spec}) /* {comment} */".format(
                    pos=pos,
                    uuid=base_id,
                    amt=(str(amount) if amount is not None else "NULL"),
                    unit=escape_sql(unit),
                    label=escape_sql(label),
                    spec=escape_sql(special),
                    comment=comment,
                )
            )
        if ing_values:
            out_lines.append("INSERT INTO ingredients (cocktail_id, position, base_ingredient_id, amount, unit, label, special)\nVALUES")
            out_lines.append(
                "    " + ",\n    ".join(ing_values) + ";\n"
            )
        else:
            # Remove the WITH clause terminator when no ingredients
            out_lines[-1] += ";\n"  # simply terminate the INSERT
            out_lines.append("\n-- (No mapped ingredients)\n")

    if unmatched:
        # Prepend DO blocks that will raise an error when the SQL script is executed
        out_lines.append("-- -------------------------------------------------------------")
        out_lines.append("-- ERROR: Unmatched base ingredients (will abort execution) --")
        out_lines.append("-- -------------------------------------------------------------")
        for ing, cocktails in sorted(unmatched.items()):
            c_list = ", ".join(sorted(cocktails))
            msg = f"Base ingredient not found: {ing} (used in: {c_list})"
            out_lines.append(
                "DO $$\nBEGIN\n    RAISE EXCEPTION '%s';\nEND $$;\n" % msg.replace("'", "''")
            )
        out_lines.append("\n")

    # Write
    OUTPUT_SQL.write_text("\n".join(out_lines), encoding="utf-8")
    print(f"Wrote {OUTPUT_SQL.relative_to(ROOT)} with {len(recipes)} cocktails.")

    # Report any unmatched ingredients
    if unmatched:
        print("\n⚠️  ERROR: The following ingredients were not found in base_ingredients and were included as fatal errors in the SQL:")
        for ing, cocktails in sorted(unmatched.items()):
            c_list = ", ".join(sorted(cocktails))
            print(f"  • {ing}  (used in: {c_list})")
        # Return non-zero exit status so CI can catch it
        import sys
        sys.exit(1)
    else:
        print("All recipe ingredients successfully matched to base_ingredients.")


if __name__ == "__main__":
    main() 