import Foundation

/// One nudge in a running session.
public struct ScheduledNudge: Codable, Identifiable, Hashable, Sendable {
    /// Stable identifier, also used as the notification request identifier.
    public var id: String
    public var fireDate: Date
    public var minutesLeft: Int
    /// Number of haptic taps: 1 = early warning, 2 = final warning, 3 = time's up.
    public var taps: Int

    public init(id: String, fireDate: Date, minutesLeft: Int, taps: Int) {
        self.id = id
        self.fireDate = fireDate
        self.minutesLeft = minutesLeft
        self.taps = taps
    }

    /// Short, discreet text for a notification banner.
    public var message: String {
        minutesLeft == 0 ? "Time's up" : "\(minutesLeft) min left"
    }
}

/// A session that has been started.
public struct ActiveSession: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var presetName: String
    public var startDate: Date
    public var endDate: Date
    public var nudges: [ScheduledNudge]
    public var target: NudgeTarget

    public init(id: UUID, presetName: String, startDate: Date, endDate: Date, nudges: [ScheduledNudge], target: NudgeTarget) {
        self.id = id
        self.presetName = presetName
        self.startDate = startDate
        self.endDate = endDate
        self.nudges = nudges
        self.target = target
    }

    /// Starts a session from a preset at `date`.
    public static func start(_ preset: SessionPreset, at date: Date, id: UUID = UUID()) -> ActiveSession {
        let p = preset.normalized()
        let end = date.addingTimeInterval(TimeInterval(p.durationMinutes * 60))
        return ActiveSession(
            id: id,
            presetName: p.name,
            startDate: date,
            endDate: end,
            nudges: NudgeScheduler.nudges(minutesBeforeEnd: p.nudgeMinutesBeforeEnd, endDate: end, sessionID: id),
            target: p.target
        )
    }

    /// Seconds remaining until the end. Negative once the session overruns.
    public func remaining(at date: Date) -> TimeInterval {
        endDate.timeIntervalSince(date)
    }

    public func isFinished(at date: Date) -> Bool {
        date >= endDate
    }

    /// Nudges whose fire date is strictly after `date`, earliest first.
    public func upcomingNudges(after date: Date) -> [ScheduledNudge] {
        nudges.filter { $0.fireDate > date }.sorted { $0.fireDate < $1.fireDate }
    }

    public func nextNudge(after date: Date) -> ScheduledNudge? {
        upcomingNudges(after: date).first
    }

    /// Nudges that are due at `date` (fire date reached) and not in `delivered`.
    /// Nudges more than `staleAfter` seconds late are skipped, so reopening the app
    /// long after a nudge does not replay it.
    public func dueNudges(at date: Date, delivered: Set<String>, staleAfter: TimeInterval = 30) -> [ScheduledNudge] {
        nudges
            .filter { !delivered.contains($0.id) }
            .filter { $0.fireDate <= date && date.timeIntervalSince($0.fireDate) <= staleAfter }
            .sorted { $0.fireDate < $1.fireDate }
    }
}

public enum NudgeScheduler {
    /// Builds nudges for the given offsets (minutes before end).
    /// Tap rule: 0 min → 3 taps (time's up); the smallest non-zero offset → 2 taps
    /// (final warning); every earlier nudge → 1 tap.
    public static func nudges(minutesBeforeEnd: [Int], endDate: Date, sessionID: UUID) -> [ScheduledNudge] {
        let offsets = Array(Set(minutesBeforeEnd.filter { $0 >= 0 })).sorted(by: >)
        let smallestNonZero = offsets.filter { $0 > 0 }.min()
        return offsets.map { minutes in
            let taps: Int
            if minutes == 0 {
                taps = 3
            } else if minutes == smallestNonZero {
                taps = 2
            } else {
                taps = 1
            }
            return ScheduledNudge(
                id: "nudgy.\(sessionID.uuidString).\(minutes)",
                fireDate: endDate.addingTimeInterval(TimeInterval(-minutes * 60)),
                minutesLeft: minutes,
                taps: taps
            )
        }
    }
}
