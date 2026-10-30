"""Run the shared corpus against the canonical Python validator."""
import argparse
import importlib.util
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("validate_cued", ROOT / "source/make-cued-deck/scripts/validate_cued.py")
validator = importlib.util.module_from_spec(spec)
spec.loader.exec_module(validator)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    fixtures = ROOT / "tests/fixtures"
    manifest = json.loads((fixtures / "manifest.json").read_text(encoding="utf-8"))
    results = []
    for case in manifest["cases"]:
        errors, warnings, _ = validator.validate_file(fixtures / case["file"])
        valid = not errors
        agrees = valid == case["valid"] and (not valid or len(warnings) == case["warnings"])
        results.append({"file": case["file"], "valid": valid, "warnings": len(warnings), "passed": agrees, "errors": errors})
    report = {"platform": "python", "cases": len(results), "passed": all(row["passed"] for row in results), "results": results}
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    for row in results:
        if not row["passed"]:
            print(json.dumps(row, ensure_ascii=True))
    print(f"{sum(row['passed'] for row in results)}/{len(results)} shared fixtures passed")
    return 0 if report["passed"] else 1

if __name__ == "__main__":
    sys.exit(main())
