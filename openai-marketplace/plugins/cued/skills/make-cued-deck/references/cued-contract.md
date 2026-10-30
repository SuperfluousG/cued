# Cued deck contract

## File

- Extension: `.cued.json`
- Encoding: UTF-8
- Schema version: `2`
- Canonical schema: `cued.schema.json`

## Root

```json
{
  "schemaVersion": 2,
  "title": "Event or deck title",
  "cards": []
}
```

Only `schemaVersion`, `title` and `cards` are allowed.

## Card

```json
{
  "id": "stable-kebab-case-id",
  "title": "Maximum six words",
  "blocks": [
    {
      "heading": "A message or category",
      "bullets": ["One useful cue"]
    },
    {
      "heading": "Second heading",
      "bullets": ["One to three cues"]
    },
    {
      "heading": "Third heading",
      "bullets": ["Never add filler"]
    }
  ]
}
```

Only `id`, `title` and `blocks` are allowed.

## Hard rules

- At least one card.
- Unique kebab-case card IDs.
- Maximum six words in a card title.
- Exactly three blocks per card.
- One non-empty heading per block.
- One to three non-empty bullets per block.
- Maximum twelve words in a bullet.
- Maximum sixty bullet words across a card.
- No timing or slide-reference fields.
- No extra properties.

## Precise portable validation rules

The schema's character limits also apply: deck title 120, card title 100,
heading 100 and bullet 180. Lengths count Unicode code points, not UTF-16
code units or displayed grapheme clusters. Text must contain something other
than whitespace. Cards and blocks must be objects; lists must be arrays;
text fields must be strings. The version is the JSON number 2 (2.0 is the
same value), never a string or boolean. A filename must end in `.cued.json`,
case-insensitively.

The existing version-2 word rule counts matches of
`[A-Za-z0-9]+(?:['-][A-Za-z0-9]+)*`. Apostrophes and hyphens inside ASCII
words stay within one word. Unicode text is supported, but this established
word counter is not a natural-language tokenizer: accented characters may
split words and non-Latin-only text may count as zero. The writing-target
warnings still apply; a warning never makes a valid deck invalid.

Within one heading, bullets must remain unique after trimming Unicode
whitespace and applying full Unicode case folding. No NFC normalisation is
applied. The players use the shared Unicode 16.0.0 rules in the fixture
corpus, including expansions such as `Straße` → `strasse`.

JSON must be UTF-8 without a byte-order mark, with quoted property names,
finite numbers and valid Unicode scalar text. Duplicate JSON properties,
trailing commas and unpaired surrogate escapes are rejected. Parsing is
limited to 128 nested containers; valid schema-version-2 decks use far fewer.
Invalid file loading must preserve the player's previous valid deck.

## Writing targets

- Target four to eight words per bullet.
- Use fragments the speaker can understand in a glance.
- Use headings as messages, functional categories or a mixture suited to the event.
- Repeat category headings when consistency helps.
- Change message headings when the card's content changes.
- Split an overloaded card rather than compressing it.

The validator treats the four-to-eight-word target as a warning. Hard rules are errors.
