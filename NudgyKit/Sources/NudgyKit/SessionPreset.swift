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

/// A reusable session template, e.g. "Weekly team meeting, 45 min, nudges at 10/5/0".
public struct SessionPreset: Codable, Identifiable, Hashable, Sendable {
    public static let minDurationMinutes = 1
    public static let maxDurationMinutes = 480
    public static let maxNudges = 6

    public var id: UUID
    public var name: String
    public var durationMinutes: Int
    /// Minutes *before the end* at which to nudge. 0 means "time's up".
    public var nudgeMinutesBeforeEnd: [Int]
    public var target: NudgeTarget

    public init(
        id: UUID = UUID(),
        name: String,
        durationMinutes: Int,
        nudgeMinutesBeforeEnd: [Int],
        target: NudgeTarget = .watch
    ) {
        self.id = id
        self.name = name
        self.durationMinutes = durationMinutes
        self.nudgeMinutesBeforeEnd = nudgeMinutesBeforeEnd
        self.target = target
    }

    /// A copy with duration clamped to the allowed range and nudges de-duplicated,
    /// limited to 0...duration, sorted from earliest (largest) to latest (0),
    /// and capped at `maxNudges` (keeping the latest ones, which matter most).
    public func normalized() -> SessionPreset {
        var copy = self
        copy.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if copy.name.isEmpty { copy.name = "Session" }
        copy.durationMinutes = min(max(durationMinutes, Self.minDurationMinutes), Self.maxDurationMinutes)
        let valid = Set(nudgeMinutesBeforeEnd.filter { $0 >= 0 && $0 <= copy.durationMinutes })
        let sortedAscending = valid.sorted()
        let capped = Array(sortedAscending.prefix(Self.maxNudges))
        copy.nudgeMinutesBeforeEnd = capped.sorted(by: >)
        return copy
    }

    public static let defaults: [SessionPreset] = [
        SessionPreset(name: "Meeting · 30 min", durationMinutes: 30, nudgeMinutesBeforeEnd: [5, 0]),
        SessionPreset(name: "Meeting · 60 min", durationMinutes: 60, nudgeMinutesBeforeEnd: [10, 5, 0]),
        SessionPreset(name: "Lesson · 50 min", durationMinutes: 50, nudgeMinutesBeforeEnd: [10, 5, 0]),
        SessionPreset(name: "Workshop · 90 min", durationMinutes: 90, nudgeMinutesBeforeEnd: [15, 5, 0])
    ]
}
