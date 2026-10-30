# Cued 1.1.0 release candidate

Cued is a small, offline speaking-card player for use beside your camera. The Windows WPF app is retained; the Mac player uses native Swift and AppKit. Both read the same schema-version-2 `.cued.json` decks.

See [QUICK-START.md](QUICK-START.md) for installation, playback and AI deck creation, and [RELEASE-NOTES.md](RELEASE-NOTES.md) for changes. Mac archives labelled `unnotarized-test` are test builds, not a normal signed public release. Build, automated tests, interactive checks and owner acceptance are separate results.

## Build and check Windows

Windows with .NET Framework 4.x:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File development\app\build.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File development\installer\build.ps1
python -B tests/test_contract.py --output test-output/python-fixtures.json
powershell -NoProfile -ExecutionPolicy Bypass -File tests\windows\run-fixtures.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File tests\windows\test-player.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File development\package.ps1 -OutputDirectory C:\path\to\new-candidate
```

The final command requires a new output directory and preserves prior candidates. Builders write only their development executables; the root `CuedSetup.exe` and `app/Cued.exe` remain retained 1.0 binaries, not the new release. Run the candidate produced by the packager.

## Build and check Mac

On a real Mac with Xcode command-line tools and Swift 5.9 or later:

```sh
bash macos/scripts/test.sh
bash macos/scripts/build.sh "$(uname -m)"
bash macos/scripts/package.sh "$(uname -m)"
```

Use the Mac guide and workflow for exact arguments and artifact locations. The support target is macOS 13. CI must run separately on Intel and Apple silicon; a successful source check on Windows is not Mac execution evidence. End users do not need developer tools for packaged playback.

## Shared deck contract

[Contract](source/make-cued-deck/references/cued-contract.md), [schema](source/make-cued-deck/references/cued.schema.json) and [shared fixtures](tests/fixtures/manifest.json) define validation. Validate a deck with:

```text
python -B source/make-cued-deck/scripts/validate_cued.py path/to/deck.cued.json
```

AI creation is a user-initiated skill handoff with an editable/copyable prompt. It does not require any particular model, automatically submit a message or install a skill. The skill source is packaged identically for both OSes; only the local destination and launch command vary.

## Retained history

[verification.md](verification.md) records the 1.0 release checks from July 2026. It is historical evidence, not acceptance of 1.1. The [sk-app architecture note](docs/sk-app-technical-overview.md) is also historical and may describe provider links or model suggestions that this release has removed.

Ownership and licence terms are unchanged.
