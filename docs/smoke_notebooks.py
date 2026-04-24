import json
from pathlib import Path


ROOT = Path(__file__).resolve().parent
NOTEBOOK_DIR = ROOT / "src" / "notebooks"
EXPECTED_NOTEBOOKS = [
    "LAlatex_basics.ipynb",
    "LAlatex_L_show_Guide.ipynb",
    "LAlatex_cases_Guide.ipynb",
    "LAlatex_aligned_Guide.ipynb",
    "LAlatex_HTML_Utilities.ipynb",
    "LAlatex_from_Python.ipynb",
]
FORBIDDEN_SNIPPETS = ["backend_available", "1.0.0-DEV"]


def main() -> None:
    missing = [name for name in EXPECTED_NOTEBOOKS if not (NOTEBOOK_DIR / name).is_file()]
    if missing:
        raise SystemExit(f"Missing documentation notebooks: {', '.join(missing)}")

    for name in EXPECTED_NOTEBOOKS:
        path = NOTEBOOK_DIR / name
        notebook = json.loads(path.read_text(encoding="utf-8"))
        nbformat = notebook.get("nbformat", 0)
        if nbformat < 4:
            raise SystemExit(f"{name}: expected nbformat >= 4, found {nbformat}")

        cells = notebook.get("cells", [])
        code_cells = [cell for cell in cells if cell.get("cell_type") == "code"]
        if not code_cells:
            raise SystemExit(f"{name}: expected at least one code cell")

        text = json.dumps(notebook, ensure_ascii=False)
        for snippet in FORBIDDEN_SNIPPETS:
            if snippet in text:
                raise SystemExit(f"{name}: forbidden snippet found: {snippet}")

    print("Notebook smoke checks passed.")


if __name__ == "__main__":
    main()
