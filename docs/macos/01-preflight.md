---
title: Cued macOS v1.0 pre-flight
status: PASS WITH RECORDED RISKS
owner: Codex
work_item: Build Cued 1.0 for macOS
asana_gid: 1216655844732073
date: 2026-07-17
---

# Cued macOS v1.0 pre-flight

## Objective

Build a faithful native macOS port of Cued 1.0, preserving the playback-only experience, Ghost mode, deck contract, provider hand-offs and frictionless session behaviour.

## Scope

In scope:

- native macOS player and landing screen;
- always-on-top card window, Ghost mode and card navigation;
- `.cued.json` loading, drag-and-drop and validation;
- ChatGPT and Claude Cowork deep links;
- macOS skill return path and first-run skill preparation;
- Apple Silicon build and unsigned inspection package;
- automated macOS compilation and contract tests;
- user and Fable inspection hand-off.

Out of scope until inspection:

- changing the Windows 1.0 visual or interaction design;
- Mac App Store distribution;
- paid Apple Developer enrolment, Developer ID signing or notarisation credentials;
- new authoring features inside Cued;
- live provider-account smoke tests that require Gregg's or a reviewer's account.

## Authorities and repository state

- Product and repository root: `C:\Users\Gregg\Bayes Ltd\Builds\Cued`
- Public remote: `https://github.com/SuperfluousG/cued`
- Baseline commit: `1db47ff51790a477c0290bdc47773709ceb40895`
- Working branch: `feature/macos-v1`
- Asana work item: `Build Cued 1.0 for macOS` (`1216655844732073`)
- Owner for this stage: Codex; product acceptance remains Gregg's.

## Design-gate decision

The full app-design divergence gate is not required. This is a faithful implementation of the already accepted Cued 1.0 interface, not a new interface or material redesign.

The governing design contract is therefore parity:

- playback only;
- no automatic session resume;
- finish returns to the landing screen;
- Open and Create remain the two landing actions;
- cards expose three headings and up to three bullets per heading without internal scrolling;
- the next-card title is the primary advance control;
- Back remains explicit;
- Ghost removes the card surface while preserving readable text, window controls and a draggable top bar;
- provider preparation remains outside the player.

Mac-native implementation details may differ where the operating system requires it, but the experience may not silently expand or collapse.

## Baseline verification

Before macOS changes:

- Windows icon build: pass.
- Windows player build: pass.
- Windows installer build: pass.
- `app/sample.cued.json` validation: pass, four cards, schema version 2.
- Git working tree: clean before branch creation.

## Data and recovery

- Existing Windows binaries and source remain on `main` and are not replaced.
- macOS work is isolated on `feature/macos-v1`.
- User decks remain ordinary files; the app has no database or migration.
- The Mac app will use `~/Documents/Cued` for visible user-owned decks and skill packages.
- Rollback is branch deletion or reverting the macOS commits; no production data is touched.

## Recorded risks

1. **No physical Mac is attached to this session.** Compilation and headless tests can run on a GitHub-hosted Apple Silicon runner, but window behaviour over Zoom, Teams, Meet, full-screen Spaces and Stage Manager requires human Mac inspection.
2. **Signing credentials are unavailable.** The inspection package will be ad-hoc signed or unsigned. A friendly public release remains blocked on Developer ID signing and notarisation.
3. **Provider-account behaviour is user-specific.** Deep-link structure can be tested, but skill enablement, folder confirmation and final desktop control require reviewer smoke tests.
4. **Global shortcut conflicts are possible.** Control-Space is retained for parity but may already be assigned to input-source switching; focused Space remains the primary guaranteed control.

## Verdict

`PASS WITH RECORDED RISKS` — safe to implement a reviewable macOS build. Release acceptance remains blocked until the named human inspection and signing decision.

