import XCTest
@testable import NudgyKit

final class PresetTests: XCTestCase {
    func testNormalizeSortsDedupesAndDropsOutOfRange() {
        let p = SessionPreset(name: "  Team  ", durationMinutes: 30, nudgeMinutesBeforeEnd: [0, 5, 5, 45, -1, 10]).normalized()
        XCTAssertEqual(p.name, "Team")
        XCTAssertEqual(p.nudgeSecondsBeforeEnd, [600, 300, 0])
    }

    func testNormalizeClampsDurationAndNamesEmpty() {
        XCTAssertEqual(SessionPreset(name: "", durationMinutes: 0, nudgeMinutesBeforeEnd: [0]).normalized().durationSeconds, 10)
        XCTAssertEqual(SessionPreset(name: "x", durationMinutes: 9999, nudgeMinutesBeforeEnd: []).normalized().durationMinutes, 480)
        XCTAssertEqual(SessionPreset(name: "   ", durationMinutes: 5, nudgeMinutesBeforeEnd: []).normalized().name, "Session")
    }

    func testNormalizeCapsNudgesKeepingLatest() {
        let p = SessionPreset(name: "x", durationMinutes: 60, nudgeMinutesBeforeEnd: [0, 1, 2, 3, 4, 5, 6, 7]).normalized()
        XCTAssertEqual(p.nudgeSecondsBeforeEnd, [300, 240, 180, 120, 60, 0])
    }

    func testHalfMinuteNudgesSurviveNormalizeAndFormat() {
        let p = SessionPreset(name: "x", durationMinutes: 15, nudgeSecondsBeforeEnd: [0, 120, 450, 300]).normalized()
        XCTAssertEqual(p.nudgeSecondsBeforeEnd, [450, 300, 120, 0])
        XCTAssertEqual(p.nudgeSummary, "7.5 · 5 · 2 · end")
        XCTAssertNil(SessionPreset(name: "x", durationMinutes: 5, nudgeSecondsBeforeEnd: []).nudgeSummary)
        XCTAssertEqual(NudgeFormat.minutes(100), "1:40")
        XCTAssertEqual(NudgeFormat.minutes(10), "10 sec")
    }

    func testDurationInSecondsAndMinutes() {
        var p = SessionPreset(name: "x", durationSeconds: 20, nudgeSecondsBeforeEnd: [10, 0])
        XCTAssertEqual(p.durationLabel, "20 sec")
        XCTAssertEqual(p.durationMinutes, 0)
        XCTAssertEqual(p.normalized().nudgeSecondsBeforeEnd, [10, 0])
        XCTAssertEqual(p.nudgeSummary, "10 sec · end")
        p.durationMinutes = 45
        XCTAssertEqual(p.durationSeconds, 2700)
        XCTAssertEqual(p.durationLabel, "45 min")
        XCTAssertEqual(SessionPreset(name: "x", durationSeconds: 90, nudgeSecondsBeforeEnd: []).durationLabel, "1:30")
    }
}

final class CatalogTests: XCTestCase {
    func testTemplatesAreNormalizedWithUniqueIDs() {
        for p in Catalog.templates { XCTAssertEqual(p, p.normalized(), p.name) }
        XCTAssertEqual(Set(Catalog.templates.map(\.id)).count, Catalog.templates.count)
    }

    func testTheFreeTimersAreAsSpecified() {
        let free = Catalog.templates.filter(Catalog.isFree)
        XCTAssertEqual(free.map(\.id), Array(Catalog.templates.prefix(3)).map(\.id), "free timers come first")
        XCTAssertEqual(free[0].durationSeconds, 20)
        XCTAssertEqual(free[0].nudgeSecondsBeforeEnd, [10, 0])
        XCTAssertTrue(free[0].repeats)
        XCTAssertEqual(free[1].durationMinutes, 5)
        XCTAssertTrue(free[1].repeats)
        XCTAssertEqual(free[2].durationMinutes, 15)
        XCTAssertEqual(free[2].nudgeSecondsBeforeEnd, [450, 300, 120, 0])
        XCTAssertFalse(free[2].repeats)
    }

    func testLockedUntilUnlocked() {
        let custom = SessionPreset(name: "Mine", durationMinutes: 10, nudgeMinutesBeforeEnd: [0])
        let all = Catalog.templates
        XCTAssertEqual(Catalog.available(templates: all, custom: [custom], unlocked: false).map(\.id), Array(all.prefix(3)).map(\.id))
        XCTAssertEqual(Catalog.locked(templates: all, unlocked: false).count, all.count - 3)
        XCTAssertFalse(Catalog.isAvailable(custom, unlocked: false), "own timers need the unlock")
        XCTAssertEqual(Catalog.available(templates: all, custom: [custom], unlocked: true).count, all.count + 1)
        XCTAssertTrue(Catalog.locked(templates: all, unlocked: true).isEmpty)
        XCTAssertTrue(Catalog.locked(templates: all, unlocked: false).contains { $0.name.hasPrefix("Pomodoro") })
    }

    func testSavedTemplatesKeepOnlyTheRepeatChoice() {
        var saved = Catalog.fiveMinutes
        saved.repeats = false
        saved.name = "Tampered"
        saved.durationMinutes = 99
        let stranger = SessionPreset(name: "Unknown", durationMinutes: 1, nudgeMinutesBeforeEnd: [])
        let merged = Catalog.templates(applying: [saved, stranger])
        XCTAssertEqual(merged.count, Catalog.templates.count)
        let five = merged.first { $0.id == Catalog.fiveMinutes.id }!
        XCTAssertFalse(five.repeats)
        XCTAssertEqual(five.name, "5 min")
        XCTAssertEqual(five.durationMinutes, 5)
        XCTAssertEqual(merged.filter { $0.id != five.id }, Catalog.templates.filter { $0.id != five.id })
    }
}

final class SchedulerTests: XCTestCase {
    let start = Date(timeIntervalSince1970: 1_000_000)

    func testTapRuleAndFireDates() {
        let s = ActiveSession.start(SessionPreset(name: "M", durationMinutes: 60, nudgeMinutesBeforeEnd: [10, 5, 0]), at: start)
        XCTAssertEqual(s.endDate, start.addingTimeInterval(3600))
        XCTAssertEqual(s.cycles, 1)
        XCTAssertFalse(s.repeats)
        XCTAssertEqual(s.nudges.map(\.secondsLeft), [600, 300, 0])
        XCTAssertEqual(s.nudges[0].fireDate, start.addingTimeInterval(50 * 60))
        XCTAssertEqual(s.nudges.map(\.message), ["10 min left", "5 min left", "Time's up"])
    }

    func testFifteenMinuteFreeTimer() {
        let s = ActiveSession.start(Catalog.fifteenMinutes, at: start)
        XCTAssertEqual(s.nudges.map { $0.fireDate.timeIntervalSince(start) }, [450, 600, 780, 900])
        XCTAssertEqual(s.nudges.map(\.message), ["7:30 left", "5 min left", "2 min left", "Time's up"])
    }

    func testNoZeroNudge() {
        let s = ActiveSession.start(SessionPreset(name: "M", durationMinutes: 45, nudgeMinutesBeforeEnd: [15, 10, 5]), at: start)
        XCTAssertEqual(s.nudges.map(\.secondsLeft), [900, 600, 300])
    }

    func testNudgeAtSessionStartIsAllowed() {
        let s = ActiveSession.start(SessionPreset(name: "M", durationMinutes: 5, nudgeMinutesBeforeEnd: [5, 0]), at: start)
        XCTAssertEqual(s.nudges.first?.fireDate, start)
    }

    func testIDsUniquePerSession() {
        let p = SessionPreset(name: "M", durationMinutes: 30, nudgeMinutesBeforeEnd: [5, 0])
        let a = ActiveSession.start(p, at: start)
        let b = ActiveSession.start(p, at: start)
        XCTAssertTrue(Set(a.nudges.map(\.id)).isDisjoint(with: Set(b.nudges.map(\.id))))
        XCTAssertEqual(Set(a.nudges.map(\.id)).count, a.nudges.count)
    }

    func testUpcomingAndNext() {
        let s = ActiveSession.start(SessionPreset(name: "M", durationMinutes: 30, nudgeMinutesBeforeEnd: [10, 5, 0]), at: start)
        let t = start.addingTimeInterval(21 * 60)
        XCTAssertEqual(s.upcomingNudges(after: t).map(\.secondsLeft), [300, 0])
        XCTAssertEqual(s.nextNudge(after: t)?.secondsLeft, 300)
        XCTAssertNil(s.nextNudge(after: s.endDate))
        XCTAssertFalse(s.isFinished(at: t))
        XCTAssertTrue(s.isFinished(at: s.endDate))
    }

    func testExpiryAfterGracePeriod() {
        let s = ActiveSession.start(SessionPreset(name: "M", durationMinutes: 30, nudgeMinutesBeforeEnd: [0]), at: start)
        XCTAssertFalse(s.isExpired(at: s.endDate))
        XCTAssertFalse(s.isExpired(at: s.endDate.addingTimeInterval(3600)))
        XCTAssertTrue(s.isExpired(at: s.endDate.addingTimeInterval(3601)))
    }

    func testDueNudgesSkipsStaleAndDelivered() {
        let s = ActiveSession.start(SessionPreset(name: "M", durationMinutes: 30, nudgeMinutesBeforeEnd: [10, 5, 0]), at: start)
        let at10 = s.nudges[0].fireDate
        XCTAssertEqual(s.dueNudges(at: at10, delivered: []).map(\.secondsLeft), [600])
        XCTAssertEqual(s.dueNudges(at: at10.addingTimeInterval(-0.1), delivered: []).count, 0)
        XCTAssertEqual(s.dueNudges(at: at10, delivered: [s.nudges[0].id]).count, 0)
        XCTAssertEqual(s.dueNudges(at: at10.addingTimeInterval(31), delivered: []).count, 0, "stale nudge must not replay")
    }
}

final class RepeatTests: XCTestCase {
    let start = Date(timeIntervalSince1970: 1_500_000)

    func testFiveMinuteRepeatPlansSixtyRounds() {
        let s = ActiveSession.start(Catalog.fiveMinutes, at: start)
        XCTAssertTrue(s.repeats)
        XCTAssertEqual(s.cycles, 60)
        XCTAssertEqual(s.nudges.count, 60)
        XCTAssertEqual(s.endDate, start.addingTimeInterval(60 * 300))
        XCTAssertEqual(s.nudges[0].fireDate, start.addingTimeInterval(300))
        XCTAssertEqual(s.nudges[1].fireDate, start.addingTimeInterval(600))
        XCTAssertEqual(Set(s.nudges.map(\.id)).count, 60)
    }

    func testQuickTestTimer() {
        let s = ActiveSession.start(Catalog.quickTest, at: start)
        XCTAssertEqual(s.cycleSeconds, 20)
        XCTAssertEqual(s.cycles, 30, "two nudges per round, 60 nudges at most")
        XCTAssertEqual(s.endDate, start.addingTimeInterval(600))
        XCTAssertEqual(Array(s.nudges.prefix(4)).map { $0.fireDate.timeIntervalSince(start) }, [10, 20, 30, 40])
        XCTAssertEqual(Array(s.nudges.prefix(2)).map(\.message), ["10 sec left", "Time's up"])
        XCTAssertEqual(s.remaining(at: start.addingTimeInterval(25)), 15)
    }

    func testRepeatOffIsASingleRound() {
        var p = Catalog.fiveMinutes
        p.repeats = false
        let s = ActiveSession.start(p, at: start)
        XCTAssertEqual(s.cycles, 1)
        XCTAssertEqual(s.nudges.count, 1)
        XCTAssertEqual(s.endDate, start.addingTimeInterval(300))
    }

    func testPomodoroIsLimitedByEightHours() {
        let pomodoro = Catalog.templates.first { $0.name.hasPrefix("Pomodoro") }!
        let s = ActiveSession.start(pomodoro, at: start)
        XCTAssertEqual(s.cycles, 16)
        XCTAssertEqual(s.endDate, start.addingTimeInterval(8 * 3600))
        XCTAssertEqual(s.nudges.count, 32)
        // Round 1: work ends at 25:00, break ends at 30:00.
        XCTAssertEqual(s.nudges[0].fireDate, start.addingTimeInterval(25 * 60))
        XCTAssertEqual(s.nudges[1].fireDate, start.addingTimeInterval(30 * 60))
    }

    func testScheduledNudgesNeverExceedTheLimit() {
        let busy = SessionPreset(name: "x", durationMinutes: 1, nudgeSecondsBeforeEnd: [50, 40, 30, 20, 10, 0], repeats: true)
        let s = ActiveSession.start(busy, at: start)
        XCTAssertEqual(s.cycles, 10)
        XCTAssertLessThanOrEqual(s.nudges.count, ActiveSession.maxScheduledNudges)
    }

    func testRepeatDropsNudgeAtRoundStart() {
        let p = SessionPreset(name: "x", durationMinutes: 5, nudgeMinutesBeforeEnd: [5, 0], repeats: true)
        let s = ActiveSession.start(p, at: start)
        XCTAssertEqual(s.cycles, 60)
        XCTAssertEqual(s.nudges.first?.fireDate, start.addingTimeInterval(300))
        XCTAssertEqual(Set(s.nudges.map(\.fireDate)).count, s.nudges.count, "no two nudges at the same moment")
    }

    func testCountdownRestartsEachRound() {
        let s = ActiveSession.start(Catalog.fiveMinutes, at: start)
        XCTAssertEqual(s.cycleIndex(at: start), 0)
        XCTAssertEqual(s.remaining(at: start), 300)
        XCTAssertEqual(s.remaining(at: start.addingTimeInterval(299)), 1)
        XCTAssertEqual(s.cycleIndex(at: start.addingTimeInterval(300)), 1)
        XCTAssertEqual(s.remaining(at: start.addingTimeInterval(300)), 300)
        XCTAssertEqual(s.remaining(at: start.addingTimeInterval(450)), 150)
        XCTAssertEqual(s.cycleIndex(at: s.endDate.addingTimeInterval(30)), 59)
        XCTAssertEqual(s.remaining(at: s.endDate.addingTimeInterval(30)), -30)
        XCTAssertEqual(s.cycleIndex(at: start.addingTimeInterval(-5)), 0)
    }

    func testEachRepeatedNudgePlaysExactlyOnce() {
        var tracker = NudgeTracker()
        var p = Catalog.fiveMinutes
        p.durationMinutes = 1
        let s = ActiveSession.start(p, at: start)
        tracker.begin(s, now: start)
        var played = 0
        var t = start
        while t <= start.addingTimeInterval(5 * 60 + 5) {
            played += tracker.takeDue(at: t).count
            t = t.addingTimeInterval(0.5)
        }
        XCTAssertEqual(played, 5)
        XCTAssertEqual(tracker.nextWakeDate(after: t), start.addingTimeInterval(6 * 60))
    }
}

final class TrackerTests: XCTestCase {
    let start = Date(timeIntervalSince1970: 2_000_000)

    func testEachNudgePlaysExactlyOnce() {
        var tracker = NudgeTracker()
        let s = ActiveSession.start(SessionPreset(name: "M", durationMinutes: 10, nudgeMinutesBeforeEnd: [5, 0]), at: start)
        tracker.begin(s, now: start)
        var played: [Int] = []
        var t = start
        while t <= s.endDate.addingTimeInterval(5) {
            played += tracker.takeDue(at: t).map(\.secondsLeft)
            t = t.addingTimeInterval(0.5)
        }
        XCTAssertEqual(played, [300, 0])
    }

    func testBackupClaimDedupesWithTimer() {
        var tracker = NudgeTracker()
        let s = ActiveSession.start(SessionPreset(name: "M", durationMinutes: 10, nudgeMinutesBeforeEnd: [5]), at: start)
        tracker.begin(s, now: start)
        let id = s.nudges[0].id
        XCTAssertEqual(tracker.takeDue(at: s.nudges[0].fireDate).count, 1)
        XCTAssertFalse(tracker.claim(nudgeID: id), "backup must not replay a timer-played nudge")
    }

    func testBackupClaimWhenTimerMissed() {
        var tracker = NudgeTracker()
        let s = ActiveSession.start(SessionPreset(name: "M", durationMinutes: 10, nudgeMinutesBeforeEnd: [5]), at: start)
        tracker.begin(s, now: start)
        let id = s.nudges[0].id
        XCTAssertTrue(tracker.claim(nudgeID: id))
        XCTAssertFalse(tracker.claim(nudgeID: id))
        XCTAssertEqual(tracker.takeDue(at: s.nudges[0].fireDate).count, 0)
        XCTAssertFalse(tracker.claim(nudgeID: "nudgy.unknown.0.300"))
    }

    func testLateSyncMarksPastNudgesDelivered() {
        var tracker = NudgeTracker()
        let s = ActiveSession.start(SessionPreset(name: "M", durationMinutes: 30, nudgeMinutesBeforeEnd: [25, 5]), at: start)
        tracker.begin(s, now: start.addingTimeInterval(10 * 60))
        XCTAssertEqual(tracker.delivered, [s.nudges[0].id])
    }

    func testNextWakeDateWalksNudgesThenExpiry() {
        var tracker = NudgeTracker()
        XCTAssertNil(tracker.nextWakeDate(after: start))
        let s = ActiveSession.start(SessionPreset(name: "M", durationMinutes: 10, nudgeMinutesBeforeEnd: [5, 0]), at: start)
        tracker.begin(s, now: start)
        XCTAssertEqual(tracker.nextWakeDate(after: start), s.nudges[0].fireDate)
        _ = tracker.takeDue(at: s.nudges[0].fireDate)
        XCTAssertEqual(tracker.nextWakeDate(after: s.nudges[0].fireDate), s.endDate)
        _ = tracker.takeDue(at: s.endDate)
        let wake = tracker.nextWakeDate(after: s.endDate)
        XCTAssertEqual(wake, s.expiryDate.addingTimeInterval(1))
        XCTAssertTrue(s.isExpired(at: wake!))
        XCTAssertNil(tracker.nextWakeDate(after: wake!))
    }

    func testNextWakeDateSkipsNudgesClaimedByBackup() {
        var tracker = NudgeTracker()
        let s = ActiveSession.start(SessionPreset(name: "M", durationMinutes: 10, nudgeMinutesBeforeEnd: [5, 0]), at: start)
        tracker.begin(s, now: start)
        XCTAssertTrue(tracker.claim(nudgeID: s.nudges[0].id))
        XCTAssertEqual(tracker.nextWakeDate(after: start), s.endDate)
    }

    func testEndClearsState() {
        var tracker = NudgeTracker()
        tracker.begin(ActiveSession.start(SessionPreset(name: "M", durationMinutes: 1, nudgeMinutesBeforeEnd: [0]), at: start), now: start)
        tracker.end()
        XCTAssertNil(tracker.session)
        XCTAssertEqual(tracker.takeDue(at: start.addingTimeInterval(60)).count, 0)
    }
}

final class DeliveryAndFormatTests: XCTestCase {
    func testDeliveryPlan() {
        XCTAssertEqual(DeliveryPlan.resolve(target: .watch, watchAvailable: true), DeliveryPlan(phone: false, watch: true))
        XCTAssertEqual(DeliveryPlan.resolve(target: .watch, watchAvailable: false), DeliveryPlan(phone: true, watch: false))
        XCTAssertEqual(DeliveryPlan.resolve(target: .phone, watchAvailable: true), DeliveryPlan(phone: true, watch: false))
        XCTAssertEqual(DeliveryPlan.resolve(target: .both, watchAvailable: true), DeliveryPlan(phone: true, watch: true))
        XCTAssertEqual(DeliveryPlan.resolve(target: .both, watchAvailable: false), DeliveryPlan(phone: true, watch: false))
    }

    func testDeliveryLabel() {
        XCTAssertEqual(DeliveryPlan(phone: true, watch: true).label, "Watch + iPhone")
        XCTAssertEqual(DeliveryPlan(phone: false, watch: true).label, "Apple Watch")
        XCTAssertEqual(DeliveryPlan(phone: true, watch: false).label, "iPhone")
    }

    func testCountdown() {
        XCTAssertEqual(CountdownFormatter.string(2700), "45:00")
        XCTAssertEqual(CountdownFormatter.string(245), "4:05")
        XCTAssertEqual(CountdownFormatter.string(3900), "1:05:00")
        XCTAssertEqual(CountdownFormatter.string(0.4), "0:01", "rounds up while counting down")
        XCTAssertEqual(CountdownFormatter.string(0), "0:00")
        XCTAssertEqual(CountdownFormatter.string(-30.7), "+0:30")
    }

    func testSyncMessageRoundTrip() throws {
        let s = ActiveSession.start(Catalog.templates[5], at: Date(timeIntervalSince1970: 3_000_000))
        for msg in [SyncMessage.start(s), .stop(sessionID: s.id), .presets(Catalog.templates)] {
            XCTAssertEqual(SyncMessage.decode(try msg.encoded()), msg)
        }
        XCTAssertNil(SyncMessage.decode(["other": 1]))
        XCTAssertNil(SyncMessage.decode([SyncMessage.payloadKey: Data("junk".utf8)]))
    }
}
