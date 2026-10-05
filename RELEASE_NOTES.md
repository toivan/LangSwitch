# LangSwitch 2.0.0

[Russian release notes](RELEASE_NOTES.ru.md) · [English README](README.md) · [Russian README](README.ru.md)

Changes from 1.4.0.

Version 2.0.0 is maintained in the [toivan/LangSwitch fork](https://github.com/toivan/LangSwitch) of the [original Nikeev/LangSwitch project](https://github.com/Nikeev/LangSwitch). The **GitHub Page** button and manual update checks now use the fork's repository and releases.

## Download and first launch

- The [release DMG](https://github.com/toivan/LangSwitch/releases) contains a universal app for Apple silicon (arm64) and Intel (x86_64), requiring macOS 12 or later.
- The app is ad-hoc signed, with no Developer ID signature or Apple notarization. macOS may block the first launch.
- For a developer-verification or notarization warning, follow the [README installation instructions](README.md#getting-started) and [Apple's app-specific Open Anyway instructions](https://support.apple.com/en-us/102445) if you trust the downloaded release. Gatekeeper remains enabled.

## Breaking changes and migration

- **macOS 12 or later is required.** Support for macOS 11 is dropped to match the minimum deployment target supported by the current macOS 27 SDK. Launch-at-login controls require macOS 13 or later.
- Existing login-item registrations are preserved when upgrading. Disable **Launch at Login** from the menu if you no longer want automatic startup.
- The menu-bar icon now appears whenever LangSwitch starts. The old saved hidden-icon preference is removed during startup, so users upgrading with a hidden icon regain access to the menu.

## Startup and menu controls

- Launch at login is now **opt-in**. Opening the app no longer registers a login item automatically.
- **Launch at Login** shows the current registration state and lets you enable or disable it. A dash indicates that macOS approval is pending; clicking the item cancels that registration. **Login Items Settings…** opens the relevant System Settings page.
- **Hide Icon** asks for confirmation and applies only to the current session. Open LangSwitch again from Finder or Spotlight to restore the icon immediately, or restart the app.

## Update checks and stability

- Numeric version comparison replaces string ordering: `1.10.0` correctly sorts after `1.9.0`. The version helper supports optional `v`/`V` prefixes, one to three numeric components, SemVer prerelease precedence, and build metadata that does not affect precedence.
- Manual update checks require a successful HTTP 200 response and valid release JSON and version tags. Malformed or oversized tags are rejected. Requests have a 15-second timeout, and overlapping checks are prevented.
- Update-check errors now distinguish unavailable public release information (HTTP 404), network failures, rate limits, access denial (HTTP 403), and other HTTP responses. The message for unavailable public release information points to the fork's Releases page.
- Core Foundation input-source ownership is handled correctly for retained Copy/Create results. Checked property conversions replace forced casts, and input-source selection errors are handled.
- UI state uses the main actor, the About window can be reopened safely, and the event monitor and pending update request are cleaned up when the app exits.

## Permissions and privacy

- Removed the unused `com.apple.security.files.user-selected.read-only` entitlement. App Sandbox and Hardened Runtime remain enabled.
- LangSwitch does not record typed text, passwords, or a history of successful language switches. Generic switching errors may still be written to standard output.
- Language switching works offline. There is no telemetry or automatic background network activity. Only a manual **Check for Updates** request contacts the GitHub releases API over HTTPS; **GitHub Page** opens the project in your browser. Updates are not downloaded or installed automatically.

## Development and test coverage

- The project uses Swift 6 language mode and the current macOS SDK. No third-party dependencies were added.
- Added the shared `ReleaseVersion` helper and XCTest coverage for numeric ordering, version normalization, prerelease precedence, build metadata, invalid versions, and numbers larger than machine integers. The shared scheme runs these logic tests without launching LangSwitch or changing login-item settings.
- The test target requires macOS 14 or later with Xcode 27's XCTest framework; the application still supports macOS 12 or later. Universal Release 2.0.0 (build 10) for Apple silicon and Intel and all eight XCTest tests were verified using Xcode 27.0, Swift 6.4, and the macOS 27 SDK. Automated validation covers compilation and version-comparison logic, without exercising the app UI or login-item interactions.
