# Nudgy

Discreet haptic nudges at set points before a session ends, on iPhone and Apple Watch.
For meeting chairs, facilitators, trainers and teachers.

## What it does

- **Timers** with nudges before the end. Every nudge is the same: one white screen flash, one ding and one strong vibration. The ding follows Silent Mode on each device; the vibration does not.
- **Free timers:** "Quick test" (20 seconds, nudges at 10 seconds left and at the end, repeating; for trying things out), "5 min" (repeat on by default) and "15 min" (nudges at 7:30, 5:00 and 2:00 left, and at the end).
- **Paid timers**, shown under "Upgrade to Access" until unlocked: Meeting 30 and 60 min, Lesson 50 min, Workshop 90 min, Pomodoro 25 + 5, and timers of your own (any length, up to 6 nudges, Watch, iPhone or both).
- **Repeat:** the loop button makes a timer restart by itself until you end it. Rounds are planned in advance, up to 60 nudges or 8 hours, because iOS allows 64 scheduled notifications per app.
- **Pomodoro:** a nudge when the 25 minutes of work end and when the 5-minute break ends, then the next round. There is no long break.
- Start a timer from the iPhone or the Watch. Both show the countdown; either can end it.
- No account, no server. Data stays on the devices.

Not built yet: agenda segments, calendar import, complications, App Store assets.

## The one-time unlock

- Sold on the iPhone only (StoreKit 2). The iPhone sends the Watch the timers the user may start, so the Watch needs no purchase logic.
- Product ID: `com.georgfasching.nudgy.unlock`. Create it in App Store Connect as a **non-consumable** in-app purchase. Until it exists, the upgrade screen says "The purchase isn't available yet."
- Builds run from Xcode (debug builds) show an "Unlock for testing" switch on the upgrade screen. It is not compiled into App Store builds.

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

- `NudgyKit`: 36 unit tests pass (Swift 6.0, Linux).
- iPhone and Watch apps: compile for the iOS and watchOS simulators in GitHub Actions (Xcode 16.4, unsigned), on every push.
- Not yet verified: running on real devices (haptics, wrist-down behaviour, iPhone ↔ Watch sync, notifications), the purchase flow, and code signing.
