import Foundation

/// The built-in timers and the free/paid rule.
public enum Catalog {
    private static func id(_ n: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-4000-8000-%012d", n))!
    }

    /// A short timer for trying things out: a nudge at 10 seconds left and at the end, repeating.
    public static let quickTest = SessionPreset(id: id(8), name: "Quick test", durationSeconds: 20, nudgeSecondsBeforeEnd: [10, 0], repeats: true)
    public static let fiveMinutes = SessionPreset(id: id(1), name: "5 min", durationMinutes: 5, nudgeSecondsBeforeEnd: [0], repeats: true)
    public static let fifteenMinutes = SessionPreset(id: id(2), name: "15 min", durationMinutes: 15, nudgeSecondsBeforeEnd: [450, 300, 120, 0])

    /// Built-in timers. The first three are free; the rest need the one-time unlock.
    public static let templates: [SessionPreset] = [
        quickTest,
        fiveMinutes,
        fifteenMinutes,
        SessionPreset(id: id(3), name: "Meeting · 30 min", durationMinutes: 30, nudgeMinutesBeforeEnd: [5, 0]),
        SessionPreset(id: id(4), name: "Meeting · 60 min", durationMinutes: 60, nudgeMinutesBeforeEnd: [10, 5, 0]),
        SessionPreset(id: id(5), name: "Lesson · 50 min", durationMinutes: 50, nudgeMinutesBeforeEnd: [10, 5, 0]),
        SessionPreset(id: id(6), name: "Workshop · 90 min", durationMinutes: 90, nudgeMinutesBeforeEnd: [15, 5, 0]),
        // 25 minutes of work, a nudge, 5 minutes of break, a nudge, and round again.
        SessionPreset(id: id(7), name: "Pomodoro · 25 + 5", durationMinutes: 30, nudgeMinutesBeforeEnd: [5, 0], repeats: true)
    ]

    public static let freeIDs: Set<UUID> = [id(8), id(1), id(2)]

    public static func isFree(_ preset: SessionPreset) -> Bool {
        freeIDs.contains(preset.id)
    }

    /// Whether the user may start this timer. Timers the user created are never free.
    public static func isAvailable(_ preset: SessionPreset, unlocked: Bool) -> Bool {
        unlocked || isFree(preset)
    }

    /// The built-in timers, keeping only the user's repeat on/off choice from `saved`.
    /// Everything else always comes from the app, so templates can change between versions.
    public static func templates(applying saved: [SessionPreset]) -> [SessionPreset] {
        let savedRepeats = Dictionary(saved.map { ($0.id, $0.repeats) }, uniquingKeysWith: { first, _ in first })
        return templates.map { template in
            var copy = template
            if let repeats = savedRepeats[template.id] { copy.repeats = repeats }
            return copy
        }
    }

    /// Timers the user may start right now, in display order.
    public static func available(templates: [SessionPreset], custom: [SessionPreset], unlocked: Bool) -> [SessionPreset] {
        (templates + custom).filter { isAvailable($0, unlocked: unlocked) }
    }

    /// Built-in timers shown under "Upgrade to Access".
    public static func locked(templates: [SessionPreset], unlocked: Bool) -> [SessionPreset] {
        templates.filter { !isAvailable($0, unlocked: unlocked) }
    }
}
