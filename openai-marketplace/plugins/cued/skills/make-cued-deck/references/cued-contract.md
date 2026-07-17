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

## Writing targets

- Target four to eight words per bullet.
- Use fragments the speaker can understand in a glance.
- Use headings as messages, functional categories or a mixture suited to the event.
- Repeat category headings when consistency helps.
- Change message headings when the card's content changes.
- Split an overloaded card rather than compressing it.

The validator treats the four-to-eight-word target as a warning. Hard rules are errors.
