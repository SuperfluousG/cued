# Cued for macOS

This folder contains the faithful native macOS port of Cued 1.0.

## Requirements

- Apple Silicon Mac.
- macOS 14 or later.
- Xcode 15.4 or a compatible newer Xcode toolchain.
- Swift 5.10 or a compatible newer Swift 5 toolchain.

## Test

```bash
cd macos
swift test
```

The tests cover the deck grammar, finish-to-landing state and both provider-link contracts. The repository workflow also validates the shipped sample deck with the portable Python validator.

## Build the inspection app

From the repository root:

```bash
bash macos/scripts/build-app.sh
```

This produces:

- `macos/dist/Cued.app`
- `macos/dist/Cued-macOS-1.0.0-inspection.zip`
- `macos/dist/SHA256SUMS.txt`

The build is Apple Silicon-only and ad-hoc signed. It verifies its bundle, signature, executable architecture and bundled skill files before packaging.

## Run during development

```bash
cd macos
swift run Cued --skip-onboarding ../app/sample.cued.json
```

Inspection-only flags:

- `--skip-onboarding` suppresses the first-run sheet.
- `--ghost` opens a supplied deck directly in Ghost mode.

These flags exist for deterministic CI screenshots; normal users do not need them.

## Packaging boundary

The build script bundles the canonical skill from `source/make-cued-deck` and the Claude ZIP from `packages`. Regenerate the provider packages after changing the skill and before building a review artefact.

Developer ID credentials do not belong in this repository. A public Mac release requires an external signing/notarisation stage and a physical-Mac smoke test.
