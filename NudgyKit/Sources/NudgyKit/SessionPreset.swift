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
    public static let maxDurationMinutes = 480
    public static let maxNudges = 6

    public var id: UUID
    public var name: String
    public var durationMinutes: Int
    /// Seconds *before the end* at which to nudge. 0 means "time's up".
    public var nudgeSecondsBeforeEnd: [Int]
    public var target: NudgeTarget
    /// Restart automatically when the time is up, until the user ends the session.
    public var repeats: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        durationMinutes: Int,
        nudgeSecondsBeforeEnd: [Int],
        target: NudgeTarget = .watch,
        repeats: Bool = false
    ) {
        self.id = id
        self.name = name
        self.durationMinutes = durationMinutes
        self.nudgeSecondsBeforeEnd = nudgeSecondsBeforeEnd
        self.target = target
        self.repeats = repeats
    }

    /// Convenience for whole-minute nudges.
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
            durationMinutes: durationMinutes,
            nudgeSecondsBeforeEnd: nudgeMinutesBeforeEnd.map { $0 * 60 },
            target: target,
            repeats: repeats
        )
    }

    public var durationSeconds: Int { durationMinutes * 60 }

    /// A copy with duration clamped to the allowed range and nudges de-duplicated,
    /// limited to 0...duration, sorted from earliest (largest) to latest (0),
    /// and capped at `maxNudges` (keeping the latest ones, which matter most).
    public func normalized() -> SessionPreset {
        var copy = self
        copy.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if copy.name.isEmpty { copy.name = "Session" }
        copy.durationMinutes = min(max(durationMinutes, Self.minDurationMinutes), Self.maxDurationMinutes)
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
    /// Seconds as minutes for display: 300 → "5", 450 → "7.5", 100 → "1:40".
    public static func minutes(_ seconds: Int) -> String {
        if seconds % 60 == 0 { return "\(seconds / 60)" }
        if seconds % 30 == 0 { return "\(seconds / 60).5" }
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
