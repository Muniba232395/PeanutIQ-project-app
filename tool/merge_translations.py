#!/usr/bin/env python3
"""Deep-merge extra translation keys into assets/translations/{en,ur}.json.

Usage: python3 tool/merge_translations.py tool/translations/phase1.json
The input file has the shape {"en": {...}, "ur": {...}}. Existing keys are overwritten.
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def merge(dst, src):
    for key, value in src.items():
        if isinstance(value, dict) and isinstance(dst.get(key), dict):
            merge(dst[key], value)
        else:
            dst[key] = value


def main(path):
    extra = json.loads(Path(path).read_text(encoding="utf-8"))
    for code, keys in extra.items():
        target = ROOT / "assets" / "translations" / f"{code}.json"
        data = json.loads(target.read_text(encoding="utf-8"))
        merge(data, keys)
        target.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"updated {target.relative_to(ROOT)}")


if __name__ == "__main__":
    main(sys.argv[1])
