import Foundation

/// One nudge in a running session.
public struct ScheduledNudge: Codable, Identifiable, Hashable, Sendable {
    /// Stable identifier, also used as the notification request identifier.
    public var id: String
    public var fireDate: Date
    /// Seconds left in the round when this nudge fires. 0 = time's up.
    public var secondsLeft: Int
    public init(id: String, fireDate: Date, secondsLeft: Int) {
        self.id = id
        self.fireDate = fireDate
        self.secondsLeft = secondsLeft
    }

    /// Short, discreet text for a notification banner.
    public var message: String {
        if secondsLeft == 0 { return "Time's up" }
        if secondsLeft < 60 { return "\(secondsLeft) sec left" }
        if secondsLeft % 60 == 0 { return "\(secondsLeft / 60) min left" }
        return String(format: "%d:%02d left", secondsLeft / 60, secondsLeft % 60)
    }
}

/// A session that has been started. A repeating timer is one session made of several
/// identical rounds, planned in advance so that backup notifications can be scheduled.
public struct ActiveSession: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    public var presetName: String
    public var startDate: Date
    /// End of the last round.
    public var endDate: Date
    public var nudges: [ScheduledNudge]
    public var target: NudgeTarget
    /// Length of one round.
    public var cycleSeconds: Int
    /// Number of rounds planned. 1 unless the timer repeats.
    public var cycles: Int

    public init(
        id: UUID, presetName: String, startDate: Date, endDate: Date,
        nudges: [ScheduledNudge], target: NudgeTarget, cycleSeconds: Int, cycles: Int
    ) {
        self.id = id
        self.presetName = presetName
        self.startDate = startDate
        self.endDate = endDate
        self.nudges = nudges
        self.target = target
        self.cycleSeconds = cycleSeconds
        self.cycles = cycles
    }

    // MARK: Limits

    /// iOS keeps at most 64 pending notifications per app; stay below that.
    public static let maxScheduledNudges = 60
    /// A repeating timer stops by itself after this long.
    public static let maxRepeatSeconds = 8 * 3600
    /// A nudge more than this many seconds late is skipped instead of played.
    public static let staleNudgeInterval: TimeInterval = 30
    /// How long a session may overrun before the apps discard it automatically.
    public static let overrunGracePeriod: TimeInterval = 3600

    /// How many rounds a (normalized) preset runs for: 1, or as many as the limits allow.
    public static func cycleCount(for preset: SessionPreset) -> Int {
        guard preset.repeats else { return 1 }
        let nudgesPerCycle = max(1, preset.nudgeSecondsBeforeEnd.filter { $0 < preset.durationSeconds }.count)
        let byNudges = maxScheduledNudges / nudgesPerCycle
        let byTime = maxRepeatSeconds / preset.durationSeconds
        return max(1, min(byNudges, byTime))
    }

    /// Starts a session from a preset at `date`.
    public static func start(_ preset: SessionPreset, at date: Date, id: UUID = UUID()) -> ActiveSession {
        let p = preset.normalized()
        let cycles = cycleCount(for: p)
        // In a repeating timer a nudge at the very start of a round would coincide with
        // the end nudge of the round before it.
        let offsets = cycles > 1 ? p.nudgeSecondsBeforeEnd.filter { $0 < p.durationSeconds } : p.nudgeSecondsBeforeEnd
        var nudges: [ScheduledNudge] = []
        for cycle in 0..<cycles {
            let cycleEnd = date.addingTimeInterval(TimeInterval((cycle + 1) * p.durationSeconds))
            nudges += NudgeScheduler.nudges(secondsBeforeEnd: offsets, cycleEnd: cycleEnd, sessionID: id, cycle: cycle)
        }
        return ActiveSession(
            id: id,
            presetName: p.name,
            startDate: date,
            endDate: date.addingTimeInterval(TimeInterval(cycles * p.durationSeconds)),
            nudges: nudges,
            target: p.target,
            cycleSeconds: p.durationSeconds,
            cycles: cycles
        )
    }

    // MARK: Rounds

    public var repeats: Bool { cycles > 1 }

    /// Zero-based round that `date` falls in, clamped to the planned rounds.
    public func cycleIndex(at date: Date) -> Int {
        let elapsed = date.timeIntervalSince(startDate)
        guard elapsed > 0, cycleSeconds > 0 else { return 0 }
        return min(cycles - 1, Int(elapsed / TimeInterval(cycleSeconds)))
    }

    /// Seconds remaining in the current round. Negative once the last round overruns.
    public func remaining(at date: Date) -> TimeInterval {
        let cycleEnd = startDate.addingTimeInterval(TimeInterval((cycleIndex(at: date) + 1) * cycleSeconds))
        return cycleEnd.timeIntervalSince(date)
    }

    /// True once the last round has ended.
    public func isFinished(at date: Date) -> Bool {
        date >= endDate
    }

    public var expiryDate: Date { endDate.addingTimeInterval(Self.overrunGracePeriod) }

    /// True once the session has overrun by more than `overrunGracePeriod`.
    public func isExpired(at date: Date) -> Bool {
        date > expiryDate
    }

    // MARK: Nudges

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
    public func dueNudges(at date: Date, delivered: Set<String>, staleAfter: TimeInterval = ActiveSession.staleNudgeInterval) -> [ScheduledNudge] {
        nudges
            .filter { !delivered.contains($0.id) }
            .filter { $0.fireDate <= date && date.timeIntervalSince($0.fireDate) <= staleAfter }
            .sorted { $0.fireDate < $1.fireDate }
    }
}

public enum NudgeScheduler {
    /// Builds the nudges of one round for the given offsets (seconds before the round ends).
    /// Every nudge is the same: one flash, one sound, one vibration.
    public static func nudges(secondsBeforeEnd: [Int], cycleEnd: Date, sessionID: UUID, cycle: Int = 0) -> [ScheduledNudge] {
        let offsets = Array(Set(secondsBeforeEnd.filter { $0 >= 0 })).sorted(by: >)
        return offsets.map { seconds in
            ScheduledNudge(
                id: "nudgy.\(sessionID.uuidString).\(cycle).\(seconds)",
                fireDate: cycleEnd.addingTimeInterval(TimeInterval(-seconds)),
                secondsLeft: seconds
            )
        }
    }
}
