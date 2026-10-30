# Cued 1.1.0 release candidate for Mac

This is an **unnotarized test build**, intended for controlled evaluation. It has an ad-hoc signature for local execution, not an Apple Developer ID signature or notarization. A downloaded copy may be blocked by Gatekeeper. This package does not establish normal public Mac release readiness. Keep normal macOS protections enabled; ask the release owner for a signed, notarized build if macOS blocks it.

## Install and use

Choose the `arm64` package for an Apple Silicon Mac or `x86_64` for an Intel Mac. The declared minimum is macOS 13; the release evidence records the actual systems tested. Extract the complete archive and move `Cued.app` into your Applications folder. Playback requires no developer tools, API keys or provider account.

Open Cued and select **Try the four-card example**. Select **Open…**, use **File → Open Deck**, drop a single `.cued.json` file onto the window, or choose Cued in Finder’s **Open With** dialogue. Cued registers only its compound deck extension as an alternate viewer; it does not claim to be the default for every JSON file. Finder may require **Other… → Enable: All Applications** to choose Cued for the compound extension. This fallback is part of the manual release check.

- **Space** or **Right arrow** advances; **Left arrow** goes back. The last card has **Finish deck**, which returns to the landing screen.
- **A− / A+** changes cue text size. A vertical scroll area keeps long cards reachable at large sizes.
- Drag the title bar to move; drag any window edge to resize. The window floats above ordinary app windows.
- **Ghost** removes the card surface while preserving visible controls. **Solid** restores the dark surface. Cued continues receiving input inside its own window; it does not intercept global keys or require Accessibility permission.
- Closing ends playback. The next launch starts on the landing screen. Text size and window position are stored locally; decks are never changed during playback.

## Create a deck

Playback works offline. Creating new cards is a separate, user-initiated workflow in your chosen AI tool.

Install the included `make-cued-deck` skill through that tool’s supported Skills or Plugins controls. `Skills/make-cued-deck-claude.zip` is the Claude upload package; `Skills/cued-openai-marketplace.zip` contains the OpenAI plugin marketplace package; `Skills/make-cued-deck` contains the portable source. An attached ZIP or opened link is not an installed skill. If your tool cannot install these packages, use the portable contract and example only when you explicitly want a manual fallback.

In Cued choose **Create a deck with your AI tool…** or **File → Create a Deck**. **Copy prompt** prepares `~/Documents/Cued/Decks` and copies a prompt containing the actual absolute destination and app paths. Paste it into your chosen tool and send it yourself. The prompt does not select a model, force a host mode or send a request. If the AI tool cannot access this Mac, download its validated `.cued.json` result and open it in Cued.

## Package checks

`VERSION.txt` identifies this candidate; `SOURCE-COMMIT.txt` binds it to source. `SHA256SUMS.txt` lists packaged files. The adjacent ZIP checksum identifies the downloaded archive. Build, fixture, packaged launch and display evidence are separate from human acceptance, signing and publication.

## Developer build and verification

On a real Mac with Xcode command-line tools:

```sh
bash macos/scripts/test.sh macos/out/evidence
bash macos/scripts/build.sh "$(uname -m)" macos/out/native
bash macos/scripts/smoke.sh macos/out/native/Cued.app macos/out/evidence
bash macos/scripts/package.sh "$(uname -m)" macos/out/native/Cued.app macos/out/packages
```

Build scripts refuse to overwrite existing bundles. Use a new output directory for a subsequent build. They copy the shared Unicode fixture resource before SwiftPM builds. `test.sh` records OS, architecture, Swift, Xcode and SDK versions. CI builds and executes separately on native Intel and arm64 runners; a universal build is not substituted for that evidence.

`smoke.sh` uses Launch Services to start the packaged `.app` and exercises its actual AppKit view and session programmatically. Its PNG files capture the app’s displayed view. This is CI evidence, not a human-operated desktop journey. The following still require actual Mac interaction: Finder Open With, file drop, physical keyboard traversal/focus, floating behaviour beside another app, normal/enlarged Retina and non-Retina-equivalent display checks, close/reopen, copied prompt inspection, and downloaded distribution under Gatekeeper.

Developer ID signing and notarization require existing authorised Apple credentials through a supported secret store. No credentials, account creation or certificate purchase are included in these scripts.
