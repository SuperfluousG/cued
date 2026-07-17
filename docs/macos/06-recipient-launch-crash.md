# Recipient launch crash: SwiftPM resource lookup

Date: 2026-07-17  
Status: fix implemented; replacement inspection build pending

## Observed failure

The first recipient inspection build crashed about 0.2 seconds after launch on an Apple Silicon `Mac16,8` running macOS 26.5.2.

The crash report identified a deliberate Swift assertion in the generated `NSBundle.module` accessor while `BundleSVGImage` was loading the provider artwork. This was an application packaging defect, not Gatekeeper, code signing, CPU architecture or user setup.

## Root cause

The app copied SwiftPM's generated resource bundle into `Cued.app/Contents/Resources`. The generated accessor searched its expected bundle location and then the absolute Swift build directory.

The GitHub runner still contained that build directory, so the packaged app found the development copy and appeared to launch successfully. A clean recipient Mac had no such directory, so the accessor asserted before the first window rendered.

## Correction

- Copy the OpenAI and Claude SVGs into the app's canonical `Contents/Resources/Brand` directory.
- Resolve packaged artwork from `Bundle.main` before using the SwiftPM development fallback.
- Verify both packaged files explicitly.
- Delete `macos/.build` before the CI launch test so the app cannot borrow build-machine resources.

## Verification gate

Do not resend the Mac build until the clean-resource workflow passes, the replacement ZIP contains the fixed bundle, and its checksum has been recorded. Recipient launch remains the decisive external check.

