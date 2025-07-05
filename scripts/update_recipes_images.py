import json
from pathlib import Path

# Paths to the JSON files
IBA_FILE = Path(__file__).resolve().parent.parent / "iba_cocktails_json.json"
RECIPES_FILE = Path(__file__).resolve().parent.parent / "recipes.json"


def load_json(path: Path):
    """Utility to load a JSON file."""
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def save_json(data, path: Path):
    """Utility to save data as pretty-printed JSON."""
    with path.open("w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write("\n")  # Ensure trailing newline


def build_name_to_image_map(iba_data):
    """Return a mapping of cocktail name (lowercase) -> image_url."""
    mapping = {}
    for cocktail in iba_data.get("cocktails", []):
        name = cocktail.get("name")
        image_url = cocktail.get("image_url")
        if name and image_url:
            mapping[name.lower()] = image_url
    return mapping


def merge_images():
    iba_data = load_json(IBA_FILE)
    recipes = load_json(RECIPES_FILE)

    name_to_image = build_name_to_image_map(iba_data)

    updated_count = 0

    for recipe in recipes:
        recipe_name = recipe.get("name", "").lower()
        if recipe_name in name_to_image and "image_url" not in recipe:
            recipe["image_url"] = name_to_image[recipe_name]
            updated_count += 1

    if updated_count == 0:
        print("No recipes were updated. Either they already had images or none matched.")
    else:
        save_json(recipes, RECIPES_FILE)
        print(f"Updated {updated_count} recipes with image URLs and saved back to {RECIPES_FILE}.")


if __name__ == "__main__":
    merge_images() 