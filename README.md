# Nudgy

Discreet haptic nudges at set points before a session ends, on iPhone and Apple Watch.
For meeting chairs, facilitators, trainers and teachers.

## What it does

- **Timers** with nudges before the end. Every nudge is the same: one white screen flash, one ding and one strong vibration. The ding follows Silent Mode on each device; the vibration does not.
- **Free timers:** "Quick test" (20 seconds, nudges at 10 seconds left and at the end, repeating; for trying things out), "5 min" (repeat on by default) and "15 min" (nudges at 7:30, 5:00 and 2:00 left, and at the end).
- **Paid timers**, shown under "Unlock with the one-time purchase" until unlocked: Meeting 30 and 60 min, Lesson 50 min, Workshop 90 min, Pomodoro 25 + 5, and timers of your own (any length, up to 6 nudges, Watch, iPhone or both).
- **Repeat:** the loop button makes a timer restart by itself until you end it. Rounds are planned in advance, up to 60 nudges or 8 hours, because iOS allows 64 scheduled notifications per app.
- **Pomodoro:** a nudge when the 25 minutes of work end and when the 5-minute break ends, then the next round. There is no long break.
- **Running screen:** the countdown, the next nudge, and every nudge of the round in words, marked Done, Next or still to come.
- **Themes:** Basic (the standard iOS look) is free and the default. The unlock adds Quiet Signal (dark, amber) and Friendly Tap (light, violet), from the design canvas boards A2 and B2. Pick one with the palette button on the timer list. The iPhone app icon changes with the theme; the Watch follows the theme but keeps one icon.
- Start a timer from the iPhone or the Watch. Both show the countdown; either can end it.
- No account, no server. Data stays on the devices.

Not built yet: agenda segments, calendar import, complications, App Store assets.

## The one-time unlock

- Sold on the iPhone only (StoreKit 2). The iPhone sends the Watch the timers the user may start and the theme to show, so the Watch needs no purchase logic.
- It unlocks the paid timers, timers of your own and the two themes. If the unlock is lost (for example after a refund), the app falls back to Basic and the primary icon.
- Product ID: `com.georgfasching.nudgy.unlock`. Create it in App Store Connect as a **non-consumable** in-app purchase. Until it exists, the upgrade screen says "The purchase isn't available yet."
- Builds run from Xcode (debug builds) have a "Test as" switch on the upgrade screen: Real purchase, Free or Paid. While unlocked, a "Remove paid features" button at the bottom of the timer list switches back to Free, even after a test purchase. Your own timers are kept. None of this is compiled into App Store builds.

## Themes

- `NudgyKit/Sources/NudgyKit/Theme.swift` — the three themes and the free/paid rule.
- `Shared/ThemeStyle.swift` — colours and type per theme, for iPhone and Watch. Basic leaves everything to the system.
- Typefaces: Space Grotesk (Quiet Signal countdown and headings) and Figtree (Friendly Tap), in `Shared/Fonts/`, under the SIL Open Font License (licence files beside them). If a font fails to load, the system font is used.
- App icons: `Nudgy/Assets.xcassets` holds `AppIcon` (Basic) and the alternate icons `AppIcon-QuietSignal` and `AppIcon-FriendlyTap`. Their names must match `Theme.alternateIconName` and `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES` in `project.yml`. The Watch has one icon (`NudgyWatch/Assets.xcassets`).

## Build

Requires a Mac with Xcode. The automated build uses Xcode 16.4; older versions are untested.

Open `Nudgy.xcodeproj` in Xcode. Select your team under Signing & Capabilities for both targets (`Nudgy`, `NudgyWatch`), then run the `Nudgy` scheme on your iPhone. The Watch app installs with it.

Bundle IDs are `com.georgfasching.nudgy` and `com.georgfasching.nudgy.watchkitapp`.

### Changing the project

`Nudgy.xcodeproj` and the `Info.plist` / entitlements files are generated from `project.yml` by [XcodeGen](https://github.com/yonaskolb/XcodeGen). Do not edit them by hand: change `project.yml` instead. On any push to a non-main branch that touches `project.yml` or the app sources, the "Generate Xcode project" workflow regenerates the project on a Mac runner and commits it to that branch. To regenerate locally:

```bash
brew install xcodegen
```

```bash
xcodegen generate
```

## How nudges are delivered

| Situation | What you get |
|---|---|
| Watch, Nudgy on screen | Strong haptic with sound, and a white flash |
| Watch, wrist down or another app in front | A notification: the system's haptic and sound, with "5 min left" |
| iPhone, Nudgy on screen | Ding, vibration and a white flash |
| iPhone, locked or in another app | A notification with the same ding and a vibration |

How: each nudge is scheduled as a local notification when the session starts, so it arrives even when Nudgy is not running. While Nudgy is on screen, it plays the nudge itself and cancels that notification. Backup notifications fire 2 seconds after the nudge time, which gives the app time to cancel them.

Known limits:

- The ding follows Silent Mode: with the iPhone's ring switch or the Watch's Silent Mode on, there is only the vibration.
- A Focus must allow Nudgy for nudges on a locked iPhone (they are marked Time Sensitive).
- With the wrist down, Watch nudges come 2 seconds after the nudge time and show the notification text.

## Layout

- `NudgyKit/` — platform-neutral logic (timers, the free/paid rule, scheduling, repeat, de-duplication, sync messages) with unit tests.
- `Nudgy/` — iPhone app (SwiftUI).
- `NudgyWatch/` — Watch app (SwiftUI).
- `Shared/` — session engine, iPhone ↔ Watch sync, notification scheduling and storage, used by both apps.
- `project.yml` — XcodeGen project definition; `Nudgy.xcodeproj` is generated from it.
- `archive/harness-engineering-trainer/` — the repository's previous content, kept for reference.

## Tests

```bash
cd NudgyKit && swift test
```

## Verification status

- `NudgyKit`: 44 unit tests pass (Swift 6.0, Linux, GitHub Actions).
- iPhone and Watch apps: compile for the iOS and watchOS simulators in GitHub Actions (Xcode 16.4, unsigned), on every push.
- Not yet verified: running on real devices (haptics, wrist-down behaviour, iPhone ↔ Watch sync, notifications), the purchase flow, code signing, the theme switch and app icon change, and the bundled typefaces loading.
