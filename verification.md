# Cued 1.0 verification

Date: 17 July 2026

## Verdict

Cued 1.0 is ready for a small trusted-friends release. The Windows player, installer, portable skill, Claude package and OpenAI plugin package build and validate together from the source included in this folder.

## Release changes

- Removed the HTML setup page and its provider assets. `CuedSetup.exe` is the only installation entry point.
- Added a nine-size Cued ghost icon and embedded it in both `Cued.exe` and `CuedSetup.exe` for the taskbar, shortcuts and Explorer.
- Updated the ChatGPT hand-off to request Work mode and GPT-5.6 Terra.
- Included the exact installed `Decks` and `Cued.exe` paths in the prepared prompt so they survive a move into Work mode.
- Kept the documented boundary explicit: the `codex://` link can prefill a prompt and workspace but cannot select Work mode, choose a model or submit the prompt.
- Promoted application and plugin metadata to version 1.0.

## Checks completed

- Rebuilt the icon, WPF player and WinForms installer from `development/`.
- Confirmed file version `1.0.0.0` and an extractable embedded icon in both executables.
- Parsed the `.ico` file and confirmed nine valid 32-bit entries from 16 to 256 pixels.
- Loaded the four-card sample deck in Cued and confirmed that the player window opened without an early exit.
- Exercised all six installer choices through their real click handlers; each changed state and none overlapped.
- Inspected the app and installer ChatGPT links for the Work-mode request, GPT-5.6 Terra, absolute Decks path and absolute Cued executable path.
- Inspected the Claude link for the prepared Cowork prompt and installed Cued folder.
- Validated the shared skill with both the OpenAI and Claude skill validators.
- Validated the OpenAI plugin manifest after its required cache-busting version update.
- Confirmed that the portable and plugin skill trees contain the same seven files and hashes.
- Validated the sample deck as schema version 2 with four cards.
- Confirmed that neither provider package contains `__pycache__` or `.pyc` entries.
- Confirmed that no `setup.html` remains in the release tree.

## SHA-256

- `app/Cued.exe`: `4A0B103C9AF49AD9B483233CF6DCC354528BAD6353B8F09129DD834A5F9E61A3`
- `CuedSetup.exe`: `172904189A98285B34E9371C2BA7CEC23B05C7D0738B613F57FE270391EDE0C2`
- `development/icon/cued.ico`: `A9715F1B5EFAFD485A15077906F648970DE3C9DAC4A67462668F7C0E1887E267`
- `packages/make-cued-deck-claude.zip`: `7F76A5E2863C8484BE67BDE502D156D85885F81AAA3C9910B4D5207831FB071E`
- `packages/cued-openai-marketplace-1.0.0.zip`: `16298D29809F3DBE37AE0FB794095EA529921B4744AFB4C5952AEB8EF2F52988`

## Remaining limits

- The binaries are not code-signed. SmartScreen may warn on another computer even though it did not appear in the latest local setup test.
- OpenAI does not document a deep-link parameter for Work mode or model selection. The prompt requests GPT-5.6 Terra, but the user may still need to accept the Work-mode hand-off and select Terra in the composer.
- A live ChatGPT provider test can create a new task and remains dependent on the recipient's account, desktop protocol handler and model access.
- Claude still requires a one-time manual skill upload through Customize, Skills, Create skill.
