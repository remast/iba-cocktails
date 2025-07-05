import json
from pathlib import Path

RECIPES_FILE = Path(__file__).resolve().parent.parent / "recipes.json"


def main():
    with RECIPES_FILE.open("r", encoding="utf-8") as f:
        recipes = json.load(f)

    original_len = len(recipes)
    filtered = [r for r in recipes if "image_url" in r]
    removed_count = original_len - len(filtered)

    if removed_count:
        with RECIPES_FILE.open("w", encoding="utf-8") as f:
            json.dump(filtered, f, ensure_ascii=False, indent=2)
            f.write("\n")
        print(f"Removed {removed_count} recipes without image_url. New total: {len(filtered)}")
    else:
        print("No recipes removed; all have image_url.")


if __name__ == "__main__":
    main() 