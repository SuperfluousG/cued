"""Regenerate the shared contract corpus and pinned Unicode rules with Python 3.14."""
from copy import deepcopy
import json
from pathlib import Path
import re
import unicodedata

assert unicodedata.unidata_version == "16.0.0", "Use Unicode 16.0.0 to preserve portable version-2 rules"

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
cases = []

def save(name, data, valid, warnings=None):
    path = HERE / name
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    entry = {"file": name, "valid": valid}
    if warnings is not None:
        entry["warnings"] = warnings
    cases.append(entry)

def raw(name, value):
    path = HERE / name
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(value if isinstance(value, bytes) else value.encode("utf-8"))
    cases.append({"file": name, "valid": False})

minimum = {"schemaVersion": 2, "title": "Small deck", "cards": [{"id": "first-card", "title": "First card", "blocks": [
    {"heading": "One", "bullets": ["One"]}, {"heading": "Two", "bullets": ["Two"]}, {"heading": "Three", "bullets": ["Three"]}]}]}
sample = json.loads((ROOT / "app/sample.cued.json").read_text(encoding="utf-8"))
save("valid/sample.cued.json", sample, True, 0)
save("valid/minimum.cued.json", minimum, True, 3)
maximum = deepcopy(minimum)
maximum["title"] = "D" * 120
maximum["cards"][0]["title"] = "One two three four five six"
for index, block in enumerate(maximum["cards"][0]["blocks"]):
    block["heading"] = "H" * 100
    block["bullets"] = ["one two three four five six seven eight nine ten eleven twelve", "one two three four five six", "one two"]
save("valid/maximum.cued.json", maximum, True, 6)
unicode = deepcopy(minimum)
unicode["title"] = "Café — 東京 🙂"
unicode["cards"][0]["blocks"][0]["bullets"] = ["Café déjà vu — 東京 🙂", "Keep don't and well-being together"]
save("valid/paths with spaces/Café 東京.cued.json", unicode, True, 2)
numeric = deepcopy(minimum)
numeric["schemaVersion"] = 2.0
save("valid/numeric-schema.cued.json", numeric, True, 3)
lengths = deepcopy(minimum)
lengths["title"] = "🙂" * 120
lengths["cards"][0]["title"] = "🙂" * 100
lengths["cards"][0]["blocks"][0]["heading"] = "🙂" * 100
lengths["cards"][0]["blocks"][0]["bullets"] = ["🙂" * 180]
save("valid/unicode-length-boundaries.cued.json", lengths, True, 3)
literal = deepcopy(minimum)
literal["cards"][0]["blocks"][0]["bullets"] = ["ß", "s"]
save("valid/unicode-distinct.cued.json", literal, True, 4)
for name, path, value in [
    ("schema-string", ["schemaVersion"], "2"), ("schema-bool", ["schemaVersion"], True),
    ("schema-wrong", ["schemaVersion"], 3), ("schema-null", ["schemaVersion"], None),
    ("root-title-number", ["title"], 42), ("root-title-empty", ["title"], " \t\n"),
    ("root-title-long", ["title"], "🙂" * 121), ("cards-empty", ["cards"], []),
    ("cards-object", ["cards"], {}), ("card-null", ["cards", 0], None),
    ("id-uppercase", ["cards", 0, "id"], "First"), ("id-trailing-newline", ["cards", 0, "id"], "first\n"),
    ("id-number", ["cards", 0, "id"], 1), ("title-seven-words", ["cards", 0, "title"], "one two three four five six seven"),
    ("card-title-long", ["cards", 0, "title"], "a" * 101), ("card-title-empty", ["cards", 0, "title"], ""),
    ("blocks-two", ["cards", 0, "blocks"], minimum["cards"][0]["blocks"][:2]),
    ("blocks-four", ["cards", 0, "blocks"], minimum["cards"][0]["blocks"] + [minimum["cards"][0]["blocks"][0]]),
    ("block-null", ["cards", 0, "blocks", 0], None),
    ("heading-empty", ["cards", 0, "blocks", 0, "heading"], "\u00a0\u001c"),
    ("heading-long", ["cards", 0, "blocks", 0, "heading"], "h" * 101),
    ("heading-number", ["cards", 0, "blocks", 0, "heading"], 1),
    ("bullets-empty", ["cards", 0, "blocks", 0, "bullets"], []),
    ("bullets-four", ["cards", 0, "blocks", 0, "bullets"], ["a", "b", "c", "d"]),
    ("bullets-string", ["cards", 0, "blocks", 0, "bullets"], "one"),
    ("bullet-null", ["cards", 0, "blocks", 0, "bullets", 0], None),
    ("bullet-number", ["cards", 0, "blocks", 0, "bullets", 0], 7),
    ("bullet-empty", ["cards", 0, "blocks", 0, "bullets", 0], "\u2003\u001f"),
    ("bullet-thirteen-words", ["cards", 0, "blocks", 0, "bullets", 0], "one two three four five six seven eight nine ten eleven twelve thirteen"),
    ("bullet-long", ["cards", 0, "blocks", 0, "bullets", 0], "x" * 181),
    ("duplicate-bullets", ["cards", 0, "blocks", 0, "bullets"], [" One ", "one"]),
    ("unicode-casefold-duplicate", ["cards", 0, "blocks", 0, "bullets"], ["Straße", "STRASSE"]),
    ("unicode-sigma-duplicate", ["cards", 0, "blocks", 0, "bullets"], ["Σ", "ς"]),
    ("unicode16-duplicate", ["cards", 0, "blocks", 0, "bullets"], ["\u1c89", "\u1c8a"]),
]:
    data = deepcopy(minimum)
    target = data
    for key in path[:-1]: target = target[key]
    target[path[-1]] = value
    save("invalid/" + name + ".cued.json", data, False)
for name, path in [("root-extra", []), ("card-extra", ["cards", 0]), ("block-extra", ["cards", 0, "blocks", 0])]:
    data = deepcopy(minimum)
    target = data
    for key in path: target = target[key]
    target["timing"] = 30
    save("invalid/" + name + ".cued.json", data, False)
data = deepcopy(minimum)
data["cards"].append(deepcopy(data["cards"][0]))
save("invalid/duplicate-ids.cued.json", data, False)
data = deepcopy(maximum)
data["cards"][0]["blocks"][0]["bullets"][2] = "one two three"
save("invalid/sixty-one-cue-words.cued.json", data, False)
save("invalid/root-array.cued.json", [], False)
save("invalid/wrong-extension.json", minimum, False)
text = json.dumps(minimum)
raw("invalid/truncated.cued.json", text[:-2])
raw("invalid/trailing-comma.cued.json", text[:-1] + ",}")
raw("invalid/duplicate-json-keys.cued.json", text.replace('"schemaVersion": 2', '"schemaVersion": 2, "schemaVersion": 2'))
raw("invalid/nonfinite.cued.json", text.replace('"schemaVersion": 2', '"schemaVersion": NaN'))
raw("invalid/unquoted-key.cued.json", text.replace('"schemaVersion"', 'schemaVersion'))
raw("invalid/utf8-bom.cued.json", b"\xef\xbb\xbf" + text.encode())
raw("invalid/invalid-utf8.cued.json", b"\xff" + text.encode())
raw("invalid/unpaired-surrogate.cued.json", text.replace('"Small deck"', '"\\ud800"'))
raw("invalid/number-overflow.cued.json", text.replace('"schemaVersion": 2', '"schemaVersion": 1e999'))
raw("invalid/leading-zero.cued.json", text.replace('"schemaVersion": 2', '"schemaVersion": 02'))
raw("invalid/trailing-content.cued.json", text + " false")
raw("invalid/nesting-limit.cued.json", "[" * 129 + "0" + "]" * 129)
for name, path, key in [("missing-schema", [], "schemaVersion"), ("missing-title", [], "title"),
                       ("missing-cards", [], "cards"), ("missing-card-id", ["cards", 0], "id"),
                       ("missing-blocks", ["cards", 0], "blocks"),
                       ("missing-heading", ["cards", 0, "blocks", 0], "heading"),
                       ("missing-bullets", ["cards", 0, "blocks", 0], "bullets")]:
    data = deepcopy(minimum)
    target = data
    for part in path: target = target[part]
    del target[key]
    save("invalid/" + name + ".cued.json", data, False)
(HERE / "manifest.json").write_text(json.dumps({"cases": cases}, indent=2) + "\n", encoding="utf-8")
rules = {"unicodeVersion": unicodedata.unidata_version,
         "casefold": {str(i): chr(i).casefold() for i in range(0x110000) if chr(i).casefold() != chr(i)},
         "whitespace": [i for i in range(0x110000) if chr(i).isspace()]}
(HERE / "unicode-rules.json").write_text(json.dumps(rules, ensure_ascii=True, separators=(",", ":")) + "\n", encoding="utf-8")
table = ";".join(f"{int(key):X}:" + ",".join(f"{ord(char):X}" for char in value) for key, value in rules["casefold"].items())
for path, pattern, replacement in [
    (ROOT / "development/app/DeckLoader.cs", r'const string table = "[^"]*";', 'const string table = "' + table + '";'),
    (ROOT / "source/make-cued-deck/scripts/validate_cued.py", r'CASEFOLD_DATA = "[^"]*"', 'CASEFOLD_DATA = "' + table + '"'),
]:
    if path.exists():
        path.write_text(re.sub(pattern, lambda match: replacement, path.read_text(encoding="utf-8")), encoding="utf-8")
print(f"Generated {len(cases)} fixtures; Unicode {unicodedata.unidata_version}")
