# Cued for Mac — inspection build

Thanks for testing Cued. This is a pre-release inspection build for Apple Silicon Macs running macOS 14 or later.

## Install

1. Drag `Cued.app` into your Mac's **Applications** folder.
2. In Applications, right-click Cued and choose **Open**.
3. Confirm **Open** if macOS warns that the app came from outside the App Store.

This build is ad-hoc signed but not yet Apple-notarised. Do not disable Gatekeeper or change your Mac's security settings. If Finder will not open it through the right-click **Open** route, send Gregg a screenshot of the exact message.

## Quick player test

1. Open Cued.
2. Select **Open** and choose `sample.cued.json` from this folder.
3. Try the next-card button, Space, the left/right arrows and Back.
4. Finish the deck and confirm Cued returns to its opening screen.
5. Close and reopen Cued and confirm it does not resume the old deck.

## Ghost test

1. Open the sample deck again.
2. Place Cued over a call or another window.
3. Select the ghost.
4. Check that the card surface disappears, the words remain readable, the top bar still drags and every visible control is still clickable.
5. If possible, repeat over a full-screen Zoom, Teams or Meet call.

## Optional AI hand-off test

On first launch, Cued installs its ChatGPT skill and places the Claude skill package in `Documents/Cued/Skills`.

- Select the OpenAI mark to check that ChatGPT opens with a prepared Cued task.
- Select the Claude mark to check that Claude Cowork opens and asks you to confirm the Cued folder.
- Neither service should submit the prompt without you.

## Send back

Please send Gregg:

- your Mac model and macOS version;
- anything that did not work;
- screenshots or a short recording for visual or clicking problems; and
- three quick headings: **Keep**, **Change**, **Kill**.

The most useful checks are Ghost-mode clicking, dragging, full-screen call behaviour and the ChatGPT/Claude return into Cued.
