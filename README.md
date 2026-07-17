# Cued 1.0

Cued is a playback-only Windows 11 speaking-card app. It keeps short prompts beside the camera during meetings, presentations, interviews, podcasts and talks.

## Install

1. Extract the Cued ZIP.
2. Run `CuedSetup.exe`.
3. Keep the suggested `%USERPROFILE%\Cued` folder or choose another location.
4. Choose Desktop and Start-menu shortcuts, then select **Install Cued**.

The setup program installs only for the current Windows account. It can also install the ChatGPT/Codex skill and reveal the Claude skill ZIP.

Cued is not code-signed. Windows may warn when it is downloaded on another computer, although it does not always do so.

## Use Cued

1. Open Cued.
2. Select **Open** and choose a `.cued.json` deck, or drag a deck onto the window.
3. Keep the card near the camera while speaking.
4. Press `Space` or select the next-card title to advance.
5. Use **Back** or the left arrow to revisit a card.
6. Select the ghost to reduce the card surface while keeping the text and controls visible.

Finishing a deck returns to the landing screen. Cued does not retain an active session.

## Create with ChatGPT

Leave **Install the Cued skill for ChatGPT and Codex** selected during setup, then restart ChatGPT if it was already open.

Select the OpenAI symbol in Cued. The prepared prompt asks ChatGPT to:

- switch the task to Work mode;
- use GPT-5.6 Terra;
- run `$make-cued-deck`;
- save the finished deck in Cued's `Decks` folder;
- open the validated deck in Cued.

OpenAI's documented `codex://` chat link can prefill a prompt and workspace, but it cannot force Work mode, select a model or send the prompt. If ChatGPT offers to move the task into Work, accept it and confirm GPT-5.6 Terra in the composer. Terra is the balanced GPT-5.6 tier; Luna is intended for lighter, higher-volume work.

If the first hand-off times out, select the OpenAI symbol again or open `Open ChatGPT with Cued.url` from the installed Cued folder.

## Create with Claude

During setup, select **Show the Claude skill ZIP when setup finishes**. In Claude:

1. Open **Customize → Skills → + Create skill**.
2. Select **Upload a skill**.
3. Choose `Skills\make-cued-deck-claude.zip` without unpacking it.
4. Enable Cued.

Attaching the ZIP to a normal Claude or Cowork conversation does not install it. After the one-time upload, the Claude symbol in Cued starts a prepared Cowork task.

## What the skill does

The skill:

1. Checks relevant supplied or connected context.
2. Confirms its understanding of the event.
3. Asks genuine gaps one at a time.
4. Agrees the running order and card count.
5. Writes and validates the complete deck.
6. Opens the deck in Cued when Windows desktop control is available.

Say **make it now** to let the skill infer the running order and create the file immediately.

Every card contains exactly three heading blocks and one to three concise bullets under each heading. Cards contain no timing or slide references and never exceed nine bullets.

## Included files

- `CuedSetup.exe` — Windows setup program.
- `app/Cued.exe` — playback application with the Cued taskbar icon.
- `app/sample.cued.json` — working four-card example.
- `source/make-cued-deck/` — portable skill source.
- `packages/make-cued-deck-claude.zip` — Claude upload package.
- `packages/cued-openai-marketplace-1.0.0.zip` — OpenAI plugin marketplace package.
- `openai-marketplace/` — unpacked OpenAI plugin marketplace.
- `development/` — application, icon and installer source.
- `verification.md` — release checks and remaining limitations.

## Build from source

On Windows 11 with .NET Framework 4.x installed:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File development\icon\build-icon.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File development\app\build.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File development\installer\build.ps1
```

The build uses only Windows and .NET Framework components; it adds no application dependencies.

## Deck contract

Decks are UTF-8 JSON using schema version 2. Validate a deck with:

```powershell
python source\make-cued-deck\scripts\validate_cued.py path\to\deck.cued.json
```

## Sk-app architecture

Cued is the reference implementation of a **sk-app**: a skill-backed application that gives an AI workflow a focused desktop GUI. The reusable technical framework — including two-way hand-offs, deep-link adapters, installation, security boundaries and a build verification matrix — is documented in [docs/sk-app-technical-overview.md](docs/sk-app-technical-overview.md).

## Official product guidance

- [ChatGPT desktop commands and deep links](https://learn.chatgpt.com/docs/reference/commands)
- [Codex models](https://learn.chatgpt.com/docs/models)
- [Claude custom Skills](https://support.claude.com/en/articles/12512198-how-to-create-custom-skills)
- [Claude Desktop links](https://support.claude.com/en/articles/14729294-open-claude-desktop-with-a-link)
