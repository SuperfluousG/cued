---
title: Cued macOS v1.0 inspection hand-off
status: READY FOR GREGG AND FABLE INSPECTION
owner: Codex
build_commit: 811ddb77e68627c7b9079f36db1f031984ad476a
ci_run: 29581549638
date: 2026-07-17
---

# Cued macOS v1.0 inspection hand-off

## Verdict

`ENGINEERING PASS; PRODUCT AND RELEASE ACCEPTANCE PENDING`

The native app compiles, tests, packages, launches and renders the landing, player and Ghost states on a clean Apple Silicon macOS 14 runner. It is ready for independent inspection, not release.

## Review build

- Branch: `feature/macos-v1`
- App build commit: `811ddb77e68627c7b9079f36db1f031984ad476a`
- GitHub Actions run: [29581549638](https://github.com/SuperfluousG/cued/actions/runs/29581549638)
- Artifact: `Cued-macOS-1.0.0-inspection`
- Inner ZIP SHA-256 for this run: `301AA7E4F0C0CD2EFA19FE82C397EAE83E3EAB9922DE83CD80A6B42F32BD15D5`
- Automated screenshots: `Cued-landing.png`, `Cued-player.png`, `Cued-ghost.png`

The ZIP is ad-hoc signed for integrity checking. It is not Developer ID-signed or notarised.

## Install for inspection

1. Download the workflow artifact from the linked run.
2. Extract the artifact, then extract `Cued-macOS-1.0.0-inspection.zip`.
3. Move `Cued.app` into Applications.
4. Open Cued from Finder. Because this is a trusted inspection build rather than a notarised release, use Finder's **Open** context action if Gatekeeper asks for confirmation.
5. First launch should report that the ChatGPT skill was installed and offer to reveal the Claude ZIP.

Do not treat Gatekeeper workarounds as an acceptable public installation journey. Signing and notarisation are a separate release gate.

## Gregg inspection

### Landing and chrome

- `Open` appears above the folder.
- `Create` appears above the real OpenAI and Claude marks.
- Settings, minimise, Ghost and close are visible and correctly aligned.
- The whole Ghost control has a generous hit area.
- Empty top-bar space drags the window; controls do not accidentally drag it.
- The window remains above ordinary application windows.

### Playback

- Open `app/sample.cued.json` or another version-2 deck.
- No text scroll appears inside a card.
- The two underlying card edges read as cards, not a clipboard.
- The next-card box uses the card background and white text.
- Space and the next-card box advance.
- Back and the left arrow rewind.
- The right arrow advances.
- The drop motion reads as one card leaving and another arriving.
- Finishing returns to the landing screen.
- Closing and reopening does not resume the previous deck.

### Ghost

- The card surface disappears while the text stays readable over a real call.
- Text retains a dark shadow.
- Chrome and outline remain visible at reduced opacity.
- Ghost, close, minimise, settings, Back and Next remain clickable.
- The top bar remains draggable.
- Test above Zoom, Teams or Meet, including a full-screen Space and Stage Manager if used.

### Settings and recovery

- Cue-text size changes reflow without creating internal scrolling.
- Ghost-text opacity changes only the Ghost text layer.
- Reduced motion removes the card-drop animation.
- An invalid JSON file produces a useful error and leaves the current state safe.
- Control-Space advances globally when it is not reserved for input-source switching.

### Provider journey

- ChatGPT opens with a prepared Cued prompt and the `~/Documents/Cued` workspace.
- The prompt remains user-controlled and is not falsely presented as submitted.
- Claude opens a Cowork task and asks for folder confirmation as expected.
- The ChatGPT skill appears after first launch or reinstall from Settings.
- The Claude ZIP appears at `~/Documents/Cued/Skills/make-cued-deck-claude.zip` and uploads normally.
- A generated deck saves into `~/Documents/Cued/Decks` and returns to Cued through `open -a Cued <deck>` or the file fallback.

## Fable independent review brief

Review the running app independently of the authored happy-path checks. Prioritise:

1. window authority transitions — open, minimise, Ghost, close, full-screen Spaces and return from another app;
2. hit testing — especially transparent areas, the Ghost control and the drag region;
3. data trust — malformed, oversized, duplicate-ID and wrong-schema decks;
4. installation authority — replacement of an existing personal OpenAI skill and the honest Claude manual boundary;
5. provider failure recovery — missing desktop app, denied folder, missing skill and unavailable desktop control;
6. keyboard conflicts and focus loss during a call; and
7. parity drift against the Windows 1.0 screenshots and behaviour.

Do not report automated compilation as evidence that full-screen overlay behaviour or provider-account integration works on a recipient Mac.

## Feedback format

For each finding record:

- severity: blocker, high, medium or low;
- state and exact action;
- expected and actual result;
- screenshot or screen recording where visual;
- whether it is a Mac defect, cross-platform skill defect or deliberate platform difference.

Gregg's visual response can use `keep / change / kill`, but include the affected state so changes remain reproducible.

## Known unperformed checks

- Physical Mac interaction and accessibility inspection.
- Zoom, Teams and Meet overlay behaviour.
- Stage Manager and real full-screen Space behaviour.
- Real ChatGPT Work and Claude Cowork account hand-offs.
- Developer ID signing, notarisation and a clean-recipient Gatekeeper journey.
- Intel Mac support, deliberately excluded because the ChatGPT macOS app requires Apple Silicon.

## Next action

Gregg and Fable inspect the linked build. Codex then triages findings, implements the agreed bounded changes, reruns the full macOS workflow and records the final reflection before merge or release.
