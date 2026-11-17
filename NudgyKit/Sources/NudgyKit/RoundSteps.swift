import Foundation

/// One nudge of the current round, as listed on the running-session screen.
public struct RoundStep: Identifiable, Hashable, Sendable {
    public enum State: String, Hashable, Sendable {
        case done
        case next
        case later
    }

    public var id: String
    /// "7:30 left", "5 min left", "Time's up".
    public var label: String
    public var state: State
}

extension ActiveSession {
    /// The nudges of the round that `date` falls in, earliest first: already played,
    /// the next one, and the ones after it.
    public func roundSteps(at date: Date) -> [RoundStep] {
        let cycle = cycleIndex(at: date)
        let cycleStart = startDate.addingTimeInterval(TimeInterval(cycle * cycleSeconds))
        let cycleEnd = cycleStart.addingTimeInterval(TimeInterval(cycleSeconds))
        let inRound = nudges
            .filter { $0.fireDate > cycleStart && $0.fireDate <= cycleEnd }
            .sorted { $0.fireDate < $1.fireDate }
        var foundNext = false
        return inRound.map { nudge in
            let state: RoundStep.State
            if nudge.fireDate <= date {
                state = .done
            } else if !foundNext {
                state = .next
                foundNext = true
            } else {
                state = .later
            }
            return RoundStep(id: nudge.id, label: nudge.message, state: state)
        }
    }
}
