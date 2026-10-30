This directory is excluded from the SwiftPM target. The build copies the canonical
tests/fixtures/unicode-rules.json directly into the application bundle's Resources.
DEBUG tests read the same table through the explicit CUED_UNICODE_RULES test input.
Release executables contain no SwiftPM resource accessor or absolute-path fallback.
