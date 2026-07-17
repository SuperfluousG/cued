---
name: make-cued-deck
description: Create or revise validated Cued speaking-card decks for meetings, presentations, interviews, podcasts and talks. Use for cues, talking points or a .cued.json deck.
---

# Make a Cued deck

Create a validated `.cued.json` deck that keeps a speaker oriented without scripting their speech.

Read [references/cued-contract.md](references/cued-contract.md) before writing or revising a deck. Use [references/example-deck.cued.json](references/example-deck.cued.json) when an example helps.

## Installation boundary

An attached skill folder or ZIP is not an installed skill. If this skill is not present in the session's available skill list, say that it must be installed through the platform's Skills interface and stop. Do not imitate an installation by reading the attached `SKILL.md` and manually running the workflow unless the user explicitly asks for that fallback.

## Route the request

- If the user supplies an existing `.cued.json`, follow **Revise a deck**.
- Otherwise follow **Create a deck**.
- Treat "make it now" as an explicit request to skip confirmation and running-order approval. Infer sensible answers from available evidence and ask only about a genuinely blocking unknown.
- Do not expose raw JSON or a full card preview unless the user requests it.

## Create a deck

### 1. Orient from available context

If the purpose is already suggested, investigate before asking introductory questions.

Use a bounded one-hop search across relevant authorised sources:

- current conversation and context files;
- attached files;
- the identified calendar event, attendees, description, links and attachments;
- directly linked documents or transcripts;
- clearly related previous conversations.

Do not trawl unrelated mail, files or conversations.

If no relevant event or source is found after the bounded search, say so in one sentence and move directly to step 3. Do not keep widening the search, narrate tool use or list unrelated results.

### 2. Confirm the inferred brief

Summarise:

- event type and subject;
- audience or participants;
- apparent outcome;
- likely areas to cover;
- material unknowns.

Separate found facts from inferences and briefly identify the sources used. Ask whether the summary is right. Wait for confirmation unless the user said "make it now".

### 3. Fill gaps one question at a time

Ask only questions that materially affect the deck. Establish:

- what the event is;
- who it is for or with;
- what must be true by the end;
- what material should shape the cues;
- what the speaker must avoid, challenge or listen for.

Do not ask for information already present.

### 4. Deepen the preparation

After confirmation, search relevant authorised sources more deeply for:

- facts and commitments;
- messages to land;
- useful questions;
- risks, sensitivities and objections;
- callbacks and unfinished business.

Constrain the search to the confirmed purpose. Flag contradictions. Never invent the user's position or commitment.

### 5. Establish the format

Infer or ask about:

- event type;
- agenda, slide deck or programme;
- whether discussion, interview or question time changes the shape of the conversation.

Do not ask for timing. Never put timings or slide numbers on live cards.

### 6. Agree the running order

Propose one recommended running order showing:

- segment title and purpose;
- proposed card count;
- draft card titles.

For slide presentations, map cards to speaking segments rather than automatically making one card per slide.

Wait for explicit running-order approval. Never compress or skip this gate because the event is short, simple or described as a test. Only "make it now" or another explicit instruction to proceed without review bypasses it.

### 7. Draft the complete deck

After approval, write all cards in one pass. Do not add a sample-card gate.

Every card must have:

- a title of no more than six words;
- exactly three heading blocks;
- one to three useful bullets under each heading;
- no more than nine bullets and sixty cue words in total;
- bullets targeting four to eight words and never exceeding twelve.

Headings may be messages supported by key points, functional categories such as Questions or Watch for, or another useful three-part grammar. They may repeat across cards or change by card. Never add filler to complete the grid.

Write glanceable prompts, not prose or a speech script. Split an overloaded card.

### 8. Validate and deliver

Write a sensibly named `.cued.json` file using schema version 2.

Run:

```text
python scripts/validate_cued.py <deck.cued.json>
```

Fix every validation error before delivery. Warnings identify density opportunities but do not invalidate the deck.

After validation, attempt to open the deck when the session can control the user's Windows or macOS desktop.

For a native Windows or macOS session, run:

```text
python scripts/open_in_cued.py <deck.cued.json>
```

For a sandboxed or Cowork session:

1. Do not assume a Linux shell proves that the user's desktop app is unavailable.
2. Check for authorised Windows or macOS shell, computer-use or desktop-control capabilities.
3. If available, place the deck at a host-accessible path and launch `Cued.exe <deck-path>` on Windows or `open -a Cued <deck-path>` on macOS through that capability.
4. Confirm the Cued process or window before claiming it opened.

If no host launch capability exists, return the valid file without treating that as a generation failure.

Use exactly one compact delivery line:

- Opened: `Opened <filename> in Cued - <count> cards, <grammar>.`
- Not opened: `<file link> - <count> cards, <grammar>. Open in Cued.`

Do not add a process recap, search narration, critique, alternative options or follow-up question unless the user requests one.

If the user explicitly asks to review before file creation, show the complete card preview and wait.

## Revise a deck

1. Read and validate the existing deck.
2. Use the user's feedback and current context; do not restart the discovery interview.
3. Preserve unaffected cards and IDs.
4. Apply the smallest coherent change.
5. Re-run validation.
6. Replace the file or save a clearly named revision, then return it.

## Quality boundary

- Preserve distinctive user language when it is concise and supported.
- Do not fabricate facts, quotations, commitments or personal views.
- Do not create live transcription, automatic advancement, slides or a teleprompter script.
- Prefer fewer strong bullets to padded cues.
