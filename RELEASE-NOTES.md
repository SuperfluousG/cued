# Cued 1.1.0-rc.1

Release candidate for a small, offline speaking-card player. This is not a declaration of combined Windows/Mac acceptance; see the accompanying release results.

- Windows retains its WPF player and per-user setup. Deck loading now enforces the shared schema, including unknown properties and wrong JSON types.
- Invalid files leave the current deck intact. Opening a file during a card transition cancels the old transition safely.
- Enlarged text scrolls inside the card; controls remain visible. Right advances through the final card consistently with Space and the next control.
- Text preferences and window geometry are local settings. Reopening starts without an active deck.
- AI creation offers a prepared prompt and copy fallback, with no named model or automatic submission claim.
- Native Swift/AppKit Mac player, architecture-specific test archives and shared fixture checks are added. Mac artifacts are explicitly unnotarized test builds until signing and normal Gatekeeper distribution have been verified.

The portable `.cued.json` schema remains version 2. Hard validation failures and writing-target warnings are distinct. No cloud account, AI API, editor, recording, auto-updater or subscription has been added.

The existing ownership/licence position is unchanged. Prior 1.0 binaries are retained separately with their original hashes.
