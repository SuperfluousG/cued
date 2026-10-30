# Cued 1.1.0 release candidate

Cued plays short speaking cards beside your camera. Playback needs no network, account, API key or AI subscription.

## Windows

Extract the entire Windows ZIP before opening `CuedSetup.exe`. Choose a folder owned by your Windows account; administrator rights are not required. Keep the `app`, `source` and `packages` folders beside setup until installation finishes. The optional skill and shortcut choices are shown before installation.

For portable use, open `app/Cued.exe` directly. Cued is unsigned; downloaded files may prompt a Windows reputation warning.

## Mac test build

Use the archive for your Mac: arm64 for Apple silicon; x86_64 for Intel. The support target is macOS 13 or later; consult the accompanying release results for the OS versions actually tested. Extract the ZIP and move `Cued.app` to Applications or a folder you own. Open the app normally.

The `unnotarized-test` label is deliberate. These builds have no Developer ID notarization and are not a normal public Mac release. Gatekeeper may block a downloaded build. Do not disable Gatekeeper; use a future signed and notarized release for ordinary distribution. Xcode, Python and a terminal are not playback requirements.

## Play a deck

1. Select **Open** and choose `sample.cued.json` for the four-card example. You can also drop a `.cued.json` onto Cued.
2. Move the window beside your camera and resize it to suit. Scroll the card if enlarged text needs more room.
3. Select the next-card control, or press Space or Right while Cued has keyboard focus. Left or **Back** revisits the previous card. **Finish deck** returns to the opening screen.
4. Select the ghost control to reduce the window surface. Its controls remain available. Select it again to restore the solid card.
5. Use Settings to adjust text. Closing Cued ends the session; reopening starts at the opening screen. Cued never edits a deck.

Windows also retains the existing Ctrl+Space shortcut to advance while another app has focus, when that shortcut is available. Mac shortcuts work inside Cued; no Accessibility permission is needed. Open another file with Ctrl+O on Windows or Command+O on Mac. Invalid files show an error and leave the last good deck available.

## Create a deck with your chosen AI tool

Install `make-cued-deck` once using your tool's supported skill installation route. Windows setup can copy the skill to your personal `.agents/skills` directory if you select that option. On Mac, copy the included `Skills/make-cued-deck` folder to `~/.agents/skills/make-cued-deck` for a host that discovers that directory, then restart or refresh that host. A ZIP attached to a chat is not an installed skill.

For Claude's skill upload route, use `make-cued-deck-claude.zip` without unpacking it: this is in `packages` on Windows and `Skills` on Mac. The same folder contains the OpenAI marketplace archive for hosts supporting local plugin marketplaces. Installation options vary by host; use its current skill/plugin interface.

Select a create option in Cued, then **Copy prompt**. Paste it into your chosen tool, review it and send it yourself. A desktop link is an optional convenience; it does not install a skill, select a model or mode, submit a message or guarantee a completed deck. The copied prompt works when a link is unavailable.

The prompt includes your actual destination: the `Decks` folder beside the Windows player, or `~/Documents/Cued/Decks` on Mac. If your AI tool cannot access that folder, save/download its validated `.cued.json` and open it in Cued yourself.
