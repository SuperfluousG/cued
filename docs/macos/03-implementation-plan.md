---
title: Cued macOS v1.0 implementation plan
status: Approved by user direction
owner: Codex
date: 2026-07-17
---

# Cued macOS v1.0 implementation plan

## Stage 1 — Contract and window spike

Deliver:

- Swift package targeting macOS 14/Apple Silicon;
- deck models and validation tests using the shipped sample;
- a borderless floating panel with the Cued dimensions and colours;
- a GitHub Actions macOS build.

Verification:

- `swift test` passes on `macos-14`;
- release executable compiles for arm64;
- the app bundle contains a valid `Info.plist` and executable.

Rollback: remove `macos/` and the workflow; Windows remains untouched.

## Stage 2 — Faithful playback loop

Deliver:

- landing screen, Open flow and drag/drop;
- exact three-heading card rendering;
- card edges, Back, next-title advance and finish-to-landing;
- focused keyboard navigation;
- settings for text size, Ghost text opacity and reduced motion;
- drop animation and no internal card scrolling.

Verification:

- unit tests cover valid and invalid deck boundaries;
- state tests cover advance, rewind and finish;
- screenshot/inspection build uses the real sample deck.

Rollback: retain Stage 1 contract/window spike.

## Stage 3 — Ghost and provider hand-offs

Deliver:

- clear Ghost surface with readable text shadow and persistent controls;
- draggable top region and reliable control hit areas;
- ChatGPT and Claude Cowork links;
- `cued://` and ordinary file return handling;
- macOS support in the shared `open_in_cued.py` helper;
- first-run skill preparation and Claude ZIP reveal route.

Verification:

- provider-link tests assert scheme, route, path and prompt contents;
- helper dry-run tests pass on Windows and macOS CI;
- app bundle declares the Cued URL scheme;
- no provider link contains source-document contents or credentials.

Rollback: playback remains usable by manual file opening.

## Stage 4 — Inspection package

Deliver:

- ad-hoc signed `Cued.app` inspection ZIP built on Apple Silicon;
- checksums and build provenance;
- Mac inspection script/checklist for Gregg and Fable;
- known-risk list separating compiled evidence from unperformed visual/account checks.

Verification:

- clean CI checkout builds, tests, packages and uploads the artefact;
- `codesign --verify --deep --strict` passes for the ad-hoc inspection bundle;
- `plutil`, `file` and `spctl` results are recorded honestly.

Rollback: keep branch and source; do not publish a release.

## Stage 5 — Review, changes and reflection

Deliver:

- Fable's independent review findings;
- Gregg's keep/change/kill inspection notes;
- bounded fixes with repeated CI verification;
- final reflection covering what transferred cleanly, what did not and what should change in the sk-app framework.

Acceptance:

- Gregg approves the running Mac experience;
- no unresolved priority-one functional or trust defect remains;
- signing/notarisation status is explicit;
- only then is the branch eligible to merge or tag.

