# LangSwitch

[English](README.md) · [Русский](README.ru.md)

A small macOS menu-bar app that cycles your enabled keyboard languages (input sources) with a short press of **Fn/🌐**. It switches sources directly, without its own language-selection popup.

This [toivan/LangSwitch fork](https://github.com/toivan/LangSwitch) builds on the [original LangSwitch project](https://github.com/Nikeev/LangSwitch), started by Nikeev, and includes the updates for version 2.0.0.

**Version 2.0.0** · [Download releases](https://github.com/toivan/LangSwitch/releases) · [Release notes](RELEASE_NOTES.md) · [Release notes in Russian](RELEASE_NOTES.ru.md)

![Original LangSwitch project demo](https://github.com/Nikeev/LangSwitch/assets/1555773/2850313a-f70d-4f76-b629-3d5798754f86)

*Demonstration from Nikeev's original LangSwitch project.*

## Benefits and privacy

- **Quick switching:** a brief Fn/🌐 press moves to the next enabled input source.
- **No letters or passwords recorded:** LangSwitch handles modifier-state events to recognize Fn/🌐 presses. It does not subscribe to ordinary key-down events or collect typed text.
- **No activity or switching history:** the app does not save a record of your keystrokes, actions, or successful input-source changes.
- **No telemetry:** there are no analytics, usage reports, or background network requests.
- **Works offline:** switching input sources needs no internet connection or account.
- **You control startup:** launch at login is optional and can be changed from the menu.

Network access happens through explicit actions: **Check for Updates** makes an HTTPS request to the GitHub releases API, and **GitHub Page** opens the repository in your browser. Generic diagnostic errors may still be printed; successful input-source switches are not logged.

## Getting started

The release DMG contains a universal app for Apple silicon (arm64) and Intel (x86_64), requiring macOS 12 or later. The app is **ad-hoc signed**: it has no Developer ID signature and has not been notarized by Apple. macOS may block its first launch.

1. Download the LangSwitch DMG from the [releases page](https://github.com/toivan/LangSwitch/releases).
2. Open the DMG and drag LangSwitch to your Applications folder.
3. In macOS Keyboard settings, disable the built-in action for the Fn/🌐 key so that each press is handled once.
4. Open LangSwitch from Applications. Its globe icon appears in the menu bar.
5. Briefly press Fn/🌐 to cycle through your enabled input sources.

If macOS blocks LangSwitch because its developer cannot be verified or it is not notarized, continue only if you trust the downloaded release. After the blocked attempt, use **Open Anyway** for LangSwitch in macOS security settings, then confirm **Open**, following [Apple's instructions](https://support.apple.com/en-us/102445). This creates an exception for this app; Gatekeeper remains enabled.

macOS controls access to global keyboard events. If Fn/🌐 presses do not work, review LangSwitch's Accessibility permission in macOS privacy settings.

## Menu controls

**Launch at Login** is available on macOS 13 or later. New installations leave it disabled. Existing login-item registrations from older versions remain visible and can be disabled from this menu.

If macOS requires approval, **Login Items Settings…** opens the relevant system settings. A dash beside **Launch at Login** means approval is pending; clicking that item cancels the registration.

**Hide Icon** hides the globe only for the current session. Open LangSwitch again from Finder or Spotlight to restore it immediately. The icon also reappears at the next app launch, including when upgrading from an older version that remembered a hidden icon.

**About LangSwitch** contains **GitHub Page** and the manual **Check for Updates** action. Update checks validate the HTTP response and release version before displaying a result. They do not download or install updates.

Update-check messages distinguish unavailable public release information (HTTP 404), network errors, request limits or access denials, and other HTTP errors. When public release information is unavailable, the message points to the fork's Releases page.

**Exit** quits the app. If launch at login is enabled, quitting does not disable it; use **Launch at Login** to change that setting.

## Requirements

- macOS 12 or later; launch-at-login controls require macOS 13 or later.
- For development: Xcode with a Swift 6 compiler and a compatible macOS SDK.
- Running the unit tests requires macOS 14 or later. This requirement applies to the test target; the application supports macOS 12.
- No third-party packages. The app uses AppKit, SwiftUI, Carbon, Foundation, and ServiceManagement from the Apple SDK.

## Building and testing

Open `LangSwitch.xcodeproj` in Xcode. Choose your own development team for a signed build.

For an unsigned development build and logic tests:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project LangSwitch.xcodeproj -scheme LangSwitch \
  -configuration Release -derivedDataPath /tmp/LangSwitch-DerivedData \
  CODE_SIGNING_ALLOWED=NO build

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -project LangSwitch.xcodeproj -scheme LangSwitch \
  -destination 'platform=macOS' -derivedDataPath /tmp/LangSwitch-DerivedData \
  CODE_SIGNING_ALLOWED=NO test
```

Change `DEVELOPER_DIR` if Xcode is installed elsewhere. Setting it per command also works when `xcode-select` points to Command Line Tools, without changing the system-wide developer directory.

The unit tests exercise version-comparison logic without launching the app. They cover numeric components, `v`/`V` prefixes, prerelease precedence, build metadata, invalid tags, and numbers too large for a machine integer.

Validated with Xcode 27.0 (27A266a), Swift 6.4, and the macOS 27 SDK: unsigned Release 2.0.0 (build 10) built successfully for arm64 and x86_64, and all 8 unit-test methods passed.

The automated checks cover compilation and version-comparison logic; they do not exercise the app UI or login-item interactions. For your own Developer ID distribution, configure your signing identity and notarize the build through Xcode.

See the [2.0.0 release notes](RELEASE_NOTES.md) for the changes in this version, or read them [in Russian](RELEASE_NOTES.ru.md).
