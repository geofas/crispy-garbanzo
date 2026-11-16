# Nudgy

Discreet haptic nudges at set points before a session ends, on iPhone and Apple Watch.
For meeting chairs, facilitators, trainers and teachers.

## What v0.1 does

- Session presets: name, length, up to 6 nudges ("10 min before the end", "at the end"), and where to nudge (Watch, iPhone, or both).
- Tap patterns: earlier nudges = 1 tap, last warning = 2 taps, end = 3 taps.
- Start a session from the iPhone or the Watch. Both show the countdown; either can end it.
- Presets are edited on the iPhone and synced to the Watch.
- No account, no server. Data stays on the devices.

Not built yet: paid/freemium (StoreKit), agenda segments, calendar import, complications, App Store assets.

## Build

Requires a Mac with Xcode 15 or later and [XcodeGen](https://github.com/yonaskolb/XcodeGen).

```bash
brew install xcodegen
```

```bash
xcodegen generate
```

```bash
open Nudgy.xcodeproj
```

In Xcode: select your team under Signing & Capabilities for both targets (`Nudgy`, `NudgyWatch`), then run the `Nudgy` scheme on your iPhone. The Watch app installs with it.

Bundle IDs are `com.georgfasching.nudgy` and `com.georgfasching.nudgy.watchkitapp`; change them in `project.yml` if needed.

## How nudges are delivered

| Situation | What you feel |
|---|---|
| Watch, Nudgy open when the session starts, session ≤ 1 hour | Distinct patterns (1/2/3 taps), wrist down |
| Watch, after 1 hour, or after pressing the crown / opening another app | A standard notification tap with "5 min left" |
| Watch, session started from the iPhone and Nudgy not opened on the Watch | A standard notification tap |
| iPhone, Nudgy on screen | Distinct patterns |
| iPhone, locked or in another app | A notification vibration (silent sound file) |

The Watch screen shows "Standard taps only" whenever the distinct patterns are not active.

Why: watchOS suspends apps when the wrist drops. Nudgy uses a Mindfulness extended runtime session to stay running, which Apple limits to 1 hour and ends when the user leaves the app. Every nudge also has a backup notification scheduled 2 seconds later; the app cancels it when it plays the nudge itself.

Known limits:

- Watch haptics also make a sound unless the Watch is in Silent Mode. Turn Silent Mode on.
- iPhone vibration needs "Play Haptics in Silent Mode" enabled in iOS Settings, and a Focus that allows Nudgy (nudges are marked Time Sensitive).
- **App Review risk:** Apple's documentation says to choose the session type "based on the app's intended use". Nudgy is not a meditation app, so the Mindfulness mode may be rejected. Fallback: remove `WKBackgroundModes` from `project.yml`; the backup notifications then deliver every nudge as a standard tap.

## Layout

- `NudgyKit/` — platform-neutral logic (presets, scheduling, de-duplication, sync messages) with unit tests.
- `Nudgy/` — iPhone app (SwiftUI).
- `NudgyWatch/` — Watch app (SwiftUI).
- `Shared/` — notification scheduling and storage used by both apps.
- `project.yml` — XcodeGen project definition.
- `archive/harness-engineering-trainer/` — the repository's previous content, kept for reference.

## Tests

```bash
cd NudgyKit && swift test
```

## Verification status

- `NudgyKit`: 19 unit tests pass (Swift 6.0, Linux).
- iPhone and Watch app code: syntax-checked only. It has **not** been compiled against the iOS/watchOS SDKs or run on a device; the first Xcode build may surface errors.
