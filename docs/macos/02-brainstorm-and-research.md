---
title: Cued macOS v1.0 brainstorm and research
status: Architecture selected
owner: Codex
date: 2026-07-17
---

# Cued macOS v1.0 brainstorm and research

## Experience sentence

This should feel like the same discreet stack of speaking cards as Cued on Windows: a quiet, camera-adjacent instrument that disappears behind the speaker's attention, never a chat client or presentation editor.

## Architecture options considered

### A. Native SwiftUI with an AppKit window shell — selected

SwiftUI can reproduce the card, landing and settings surfaces with little infrastructure. A small AppKit `NSPanel` shell supplies the Mac-specific behaviours that matter: floating window level, borderless chrome, full-screen Space participation, file opening and window dragging.

Advantages:

- smallest distributable runtime;
- best fit for transparent and floating Mac window behaviour;
- native keyboard, accessibility and Finder integration;
- no third-party application dependency;
- simple Apple Silicon build on GitHub's macOS runner.

Risks:

- the WPF UI code is a behavioural reference rather than reusable source;
- a small amount of AppKit interop is unavoidable;
- visual parity needs human inspection on a real display.

### B. Avalonia/.NET

This retains C# and some conceptual similarity to WPF, but almost all of Cued's current 1,102-line interface is constructed directly from WPF types. The UI would still be rewritten, while transparent panel behaviour, packaging and Mac conventions would add a framework-specific layer.

Rejected because language reuse does not create enough implementation reuse to justify a new runtime dependency.

### C. Electron or Tauri

Both can create cross-platform windows and deep links. Electron is disproportionate for a small playback overlay. Tauri is smaller but adds a web UI, Rust tooling and platform integration without removing the native window-testing requirement.

Rejected because the app is an instrument-sized native surface, not a web product.

## Selected technical shape

```text
macos/
├── Package.swift
├── Sources/CuedMac/
│   ├── AppDelegate and floating panel
│   ├── SwiftUI landing, player and settings
│   ├── deck model, loader and validator
│   ├── provider-link adapter
│   └── first-run support-file installer
├── Tests/CuedMacTests/
├── Resources/
└── scripts/
    ├── build-app.sh
    └── package-inspection.sh
```

The Windows implementation remains unchanged. The shared assets are the deck schema, fixtures, skills and behavioural contract rather than a new cross-platform UI framework.

## Research findings

### Supported baseline

Target macOS 14 on Apple Silicon. This matches the current minimum for the ChatGPT macOS app, which is macOS 14 and M1 or later. Supporting Intel or older macOS would not make the complete ChatGPT-backed Cued journey available.

### Floating and full-screen behaviour

AppKit exposes window collection behaviours for Spaces, Stage Manager and full screen. Cued will use a floating panel that can join all Spaces and act as a full-screen auxiliary window. This is the closest supported fit for placing cards over a call without creating a normal document window.

### Deep links

- ChatGPT retains the `codex://` scheme. A new-thread link can carry a prefilled prompt and an absolute local workspace path, but it does not submit the prompt or force Work mode/model selection.
- Claude Desktop supports `claude://cowork/new` on macOS. It accepts a prefilled prompt plus folder/file attachments; linked folders remain subject to Claude's confirmation.
- Cued will also register `cued://` as a return route, while keeping ordinary file opening as the durable fallback.

### Installation

The Mac app will be a normal `.app` bundle. First launch prepares `~/Documents/Cued/Decks`, installs the bundled OpenAI skill into `~/.agents/skills/make-cued-deck`, and copies the Claude upload ZIP into `~/Documents/Cued/Skills`.

Claude personal skills still require the user-controlled upload/enable flow. Cued must show the package and instructions rather than pretending that installation happened automatically.

### Distribution

GitHub provides Apple Silicon macOS runners suitable for Swift builds and tests. An inspection bundle can therefore be compiled without a local Mac. Public direct distribution should use a Developer ID certificate and Apple notarisation; those credentials are intentionally not part of the repository.

## Behavioural parity map

| Windows 1.0 | macOS implementation |
| --- | --- |
| WPF borderless topmost window | Borderless floating `NSPanel` hosting SwiftUI |
| Custom draggable top bar | AppKit drag region behind custom controls |
| Settings, minimise, Ghost, close | Same ordering and explicit hit areas |
| Transparent Ghost surface | Clear window/card surfaces, text shadow and reduced chrome opacity |
| Ctrl-Space global advance | Control-Space registration plus focused Space |
| Left/right card navigation | Left/right arrows and explicit Back/Next |
| File picker and drag/drop | `NSOpenPanel`, Finder open and SwiftUI drop handling |
| `Cued.exe <deck>` return | `open -a Cued <deck>` and `cued://open?path=...` |
| Installer copies skill | First-run app support installation |
| Windows shortcuts | Applications/Dock conventions; no desktop shortcut installer |

## Forbidden substitutions

- Do not turn Cued into a menu-bar-only app.
- Do not replace the two-column landing screen with a settings wizard.
- Do not put editing or AI chat inside the player.
- Do not make Ghost mode click-through; its controls and drag area must remain operable.
- Do not add text scrolling inside a card.
- Do not silently reopen the last deck.
- Do not treat an unsigned CI build as a public release.

## Official sources

- [OpenAI: ChatGPT macOS requirements](https://help.openai.com/en/articles/9395554-what-are-the-system-requirements-for-the-chatgpt-macos-app)
- [OpenAI: ChatGPT desktop commands and deep links](https://learn.chatgpt.com/docs/reference/commands)
- [Anthropic: Open Claude Desktop with a link](https://support.claude.com/en/articles/14729294-open-claude-desktop-with-a-link)
- [Apple: NSWindow collection behaviour](https://developer.apple.com/documentation/appkit/nswindow/collectionbehavior-swift.struct)
- [Apple: Full-screen auxiliary windows](https://developer.apple.com/documentation/appkit/nswindow/collectionbehavior-swift.struct/fullscreenauxiliary)
- [Apple: Registering URL schemes](https://developer.apple.com/documentation/bundleresources/information-property-list/cfbundleurltypes)
- [Apple: Distributing software on macOS](https://developer.apple.com/macos/distribution/)
- [GitHub: Hosted runner reference](https://docs.github.com/en/actions/reference/runners/github-hosted-runners)
- [GitHub: Building and testing Swift](https://docs.github.com/en/actions/tutorials/build-and-test-code/swift)

