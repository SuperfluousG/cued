---
title: Cued macOS v1.0 build reflection
status: Interim — awaiting Gregg and Fable inspection
owner: Codex
date: 2026-07-17
---

# Cued macOS v1.0 build reflection

## Current verdict

The technical thesis held: Cued's deck contract, skill workflow and provider hand-offs were portable, while the player itself was small enough to reimplement natively without a shared UI framework.

This is an engineering reflection, not a product-acceptance reflection. The latter remains open until the running app is inspected on a physical Mac.

## What transferred cleanly

- The version-2 deck grammar moved directly into Swift and remained compatible with the portable Python validator.
- The playback state machine stayed small: open, advance, rewind, finish and return to landing.
- ChatGPT and Claude deep links required path and prompt changes, not a different architecture.
- The skill needed only an operating-system-neutral return section and a macOS branch in `open_in_cued.py`.
- The existing icon and provider vector paths translated cleanly into Mac assets.
- GitHub's Apple Silicon runner was sufficient for compilation, unit tests, bundle construction, ad-hoc signing, launch checking and deterministic screenshots.

## What required genuine platform work

- The WPF interface was a behavioural specification, not reusable implementation. SwiftUI reproduced the surface while AppKit supplied the floating panel, Spaces behaviour, application events and custom URL handling.
- The Windows installer could not be copied conceptually. A Mac `.app` cannot write decks into its own bundle, so Cued now uses `~/Documents/Cued` and prepares support files on first launch.
- A compound `.cued.json` extension is not a clean Launch Services document type. The durable Mac return route is therefore `open -a Cued <deck>` or `cued://open?path=...`, with manual Open and drag/drop retained.
- Global Control-Space registration is possible, but the shortcut may conflict with the user's input-source settings. It cannot be the only advance path.
- Signing is a product concern, not packaging polish. An ad-hoc signed artifact proves bundle integrity but does not provide a non-technical Gatekeeper journey.

## Defects caught by the process

1. The first regenerated Claude ZIP included a local `__pycache__` created by a syntax check. The package was rebuilt from an explicit file manifest and the archive contents were re-inspected. Future package scripts should always build from allowlisted sources, never copy an entire working skill folder blindly.
2. The initial Swift build passed but emitted warnings that would become Swift 6 errors. The hot-key constant and actor-isolated test were corrected before hand-off.
3. The GitHub connector could not create the draft PR because the integration lacked write permission. The authenticated CLI fallback created the PR without changing repository content.
4. Compilation alone would have hidden visual drift. Packaged-app launch and screenshots made the landing, player, Ghost state, provider marks and taskbar icon inspectable before human Mac access.

## Framework learning for later sk-apps

- Share the domain contract and skill, not necessarily the UI technology.
- Treat provider deep links and return helpers as explicit operating-system adapters.
- Keep user-owned output outside application bundles from the start.
- Make package contents an allowlist and test the final archive.
- Add a headless provider-link test and a packaged-app launch check for every platform.
- Separate four verdicts: compile, engineering behaviour, human product acceptance and distributable release readiness.

## Pending reflection inputs

After inspection, append:

- Gregg's keep/change/kill decisions;
- Fable's independent trust and failure-path findings;
- changes accepted, rejected or deferred;
- repeated verification evidence;
- the final product and release verdict; and
- any rule that should be promoted into the sk-app technical overview or a future `build-sk-app` skill.
