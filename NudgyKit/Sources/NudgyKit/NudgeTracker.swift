import Foundation

/// Platform-neutral bookkeeping for a running session: which nudges were delivered,
/// so the in-app timer and the backup notification never both fire for one nudge.
public struct NudgeTracker: Sendable {
    public private(set) var session: ActiveSession?
    public private(set) var delivered: Set<String> = []

    public init() {}

    public mutating func begin(_ session: ActiveSession, now: Date) {
        self.session = session
        // Anything already in the past when the session arrives (e.g. a late sync) counts as delivered.
        delivered = Set(session.nudges.filter { now.timeIntervalSince($0.fireDate) > ActiveSession.staleNudgeInterval }.map(\.id))
    }

    public mutating func end() {
        session = nil
        delivered = []
    }

    /// Returns nudges to play now and marks them delivered.
    public mutating func takeDue(at date: Date) -> [ScheduledNudge] {
        guard let session else { return [] }
        let due = session.dueNudges(at: date, delivered: delivered)
        for nudge in due { delivered.insert(nudge.id) }
        return due
    }

    /// When the app next needs to wake: the next undelivered nudge, or, once none remain,
    /// just after the session expires. Nil when there is nothing left to do.
    public func nextWakeDate(after date: Date) -> Date? {
        guard let session else { return nil }
        let pending = session.nudges
            .filter { !delivered.contains($0.id) && $0.fireDate > date }
            .map(\.fireDate)
            .min()
        if let pending { return pending }
        let expiry = session.expiryDate.addingTimeInterval(1)
        return expiry > date ? expiry : nil
    }

    /// Called when a backup notification arrives while the app is in the foreground.
    /// Returns true if the nudge still needs to be played (and marks it delivered).
    public mutating func claim(nudgeID: String) -> Bool {
        guard let session, session.nudges.contains(where: { $0.id == nudgeID }) else { return false }
        return delivered.insert(nudgeID).inserted
    }
}
