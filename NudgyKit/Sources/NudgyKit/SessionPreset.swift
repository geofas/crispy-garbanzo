import Foundation

/// Which device(s) should deliver the nudges for a session.
public enum NudgeTarget: String, Codable, CaseIterable, Hashable, Sendable {
    case watch
    case phone
    case both

    public var label: String {
        switch self {
        case .watch: return "Apple Watch"
        case .phone: return "iPhone"
        case .both: return "Watch + iPhone"
        }
    }
}

/// A reusable timer, e.g. "Weekly team meeting, 45 min, nudges at 10/5/0".
public struct SessionPreset: Codable, Identifiable, Hashable, Sendable {
    public static let minDurationMinutes = 1
    /// Shortest timer the app will run (built-in timers can be shorter than a minute).
    public static let minDurationSeconds = 10
    public static let maxDurationMinutes = 480
    public static let maxNudges = 6

    public var id: UUID
    public var name: String
    public var durationSeconds: Int
    /// Seconds *before the end* at which to nudge. 0 means "time's up".
    public var nudgeSecondsBeforeEnd: [Int]
    public var target: NudgeTarget
    /// Restart automatically when the time is up, until the user ends the session.
    public var repeats: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        durationSeconds: Int,
        nudgeSecondsBeforeEnd: [Int],
        target: NudgeTarget = .watch,
        repeats: Bool = false
    ) {
        self.id = id
        self.name = name
        self.durationSeconds = durationSeconds
        self.nudgeSecondsBeforeEnd = nudgeSecondsBeforeEnd
        self.target = target
        self.repeats = repeats
    }

    /// Convenience for a length in whole minutes.
    public init(
        id: UUID = UUID(),
        name: String,
        durationMinutes: Int,
        nudgeSecondsBeforeEnd: [Int],
        target: NudgeTarget = .watch,
        repeats: Bool = false
    ) {
        self.init(
            id: id,
            name: name,
            durationSeconds: durationMinutes * 60,
            nudgeSecondsBeforeEnd: nudgeSecondsBeforeEnd,
            target: target,
            repeats: repeats
        )
    }

    /// Convenience for a length and nudges in whole minutes.
    public init(
        id: UUID = UUID(),
        name: String,
        durationMinutes: Int,
        nudgeMinutesBeforeEnd: [Int],
        target: NudgeTarget = .watch,
        repeats: Bool = false
    ) {
        self.init(
            id: id,
            name: name,
            durationSeconds: durationMinutes * 60,
            nudgeSecondsBeforeEnd: nudgeMinutesBeforeEnd.map { $0 * 60 },
            target: target,
            repeats: repeats
        )
    }

    /// Length in whole minutes (rounded down). Setting it makes the timer a whole number of minutes.
    public var durationMinutes: Int {
        get { durationSeconds / 60 }
        set { durationSeconds = newValue * 60 }
    }

    /// "20 sec", "15 min", or "1:30" for a length that is neither.
    public var durationLabel: String {
        if durationSeconds < 60 { return "\(durationSeconds) sec" }
        if durationSeconds % 60 == 0 { return "\(durationSeconds / 60) min" }
        return String(format: "%d:%02d", durationSeconds / 60, durationSeconds % 60)
    }

    /// A copy with duration clamped to the allowed range and nudges de-duplicated,
    /// limited to 0...duration, sorted from earliest (largest) to latest (0),
    /// and capped at `maxNudges` (keeping the latest ones, which matter most).
    public func normalized() -> SessionPreset {
        var copy = self
        copy.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if copy.name.isEmpty { copy.name = "Session" }
        copy.durationSeconds = min(max(durationSeconds, Self.minDurationSeconds), Self.maxDurationMinutes * 60)
        let valid = Set(nudgeSecondsBeforeEnd.filter { $0 >= 0 && $0 <= copy.durationSeconds })
        let capped = Array(valid.sorted().prefix(Self.maxNudges))
        copy.nudgeSecondsBeforeEnd = capped.sorted(by: >)
        return copy
    }

    /// "7.5 · 5 · 2 · end", or nil when there are no nudges.
    public var nudgeSummary: String? {
        guard !nudgeSecondsBeforeEnd.isEmpty else { return nil }
        return nudgeSecondsBeforeEnd
            .sorted(by: >)
            .map { $0 == 0 ? "end" : NudgeFormat.minutes($0) }
            .joined(separator: " · ")
    }
}

public enum NudgeFormat {
    /// Seconds as minutes for display: 300 → "5", 450 → "7.5", 100 → "1:40", 10 → "10 sec".
    public static func minutes(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds) sec" }
        if seconds % 60 == 0 { return "\(seconds / 60)" }
        if seconds % 30 == 0 { return "\(seconds / 60).5" }
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
