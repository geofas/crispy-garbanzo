import XCTest
@testable import NudgyKit

final class PresetTests: XCTestCase {
    func testNormalizeSortsDedupesAndDropsOutOfRange() {
        let p = SessionPreset(name: "  Team  ", durationMinutes: 30, nudgeMinutesBeforeEnd: [0, 5, 5, 45, -1, 10]).normalized()
        XCTAssertEqual(p.name, "Team")
        XCTAssertEqual(p.nudgeMinutesBeforeEnd, [10, 5, 0])
    }

    func testNormalizeClampsDurationAndNamesEmpty() {
        XCTAssertEqual(SessionPreset(name: "", durationMinutes: 0, nudgeMinutesBeforeEnd: [0]).normalized().durationMinutes, 1)
        XCTAssertEqual(SessionPreset(name: "x", durationMinutes: 9999, nudgeMinutesBeforeEnd: []).normalized().durationMinutes, 480)
        XCTAssertEqual(SessionPreset(name: "   ", durationMinutes: 5, nudgeMinutesBeforeEnd: []).normalized().name, "Session")
    }

    func testNormalizeCapsNudgesKeepingLatest() {
        let p = SessionPreset(name: "x", durationMinutes: 60, nudgeMinutesBeforeEnd: [0, 1, 2, 3, 4, 5, 6, 7]).normalized()
        XCTAssertEqual(p.nudgeMinutesBeforeEnd, [5, 4, 3, 2, 1, 0])
    }

    func testDefaultsAreAlreadyNormalized() {
        for p in SessionPreset.defaults { XCTAssertEqual(p, p.normalized(), p.name) }
    }
}

final class SchedulerTests: XCTestCase {
    let start = Date(timeIntervalSince1970: 1_000_000)

    func testTapRuleAndFireDates() {
        let s = ActiveSession.start(SessionPreset(name: "M", durationMinutes: 60, nudgeMinutesBeforeEnd: [10, 5, 0]), at: start)
        XCTAssertEqual(s.endDate, start.addingTimeInterval(3600))
        XCTAssertEqual(s.nudges.map(\.minutesLeft), [10, 5, 0])
        XCTAssertEqual(s.nudges.map(\.taps), [1, 2, 3])
        XCTAssertEqual(s.nudges[0].fireDate, start.addingTimeInterval(50 * 60))
        XCTAssertEqual(s.nudges.map(\.message), ["10 min left", "5 min left", "Time's up"])
    }

    func testSingleNonZeroNudgeIsFinalWarning() {
        let s = ActiveSession.start(SessionPreset(name: "M", durationMinutes: 20, nudgeMinutesBeforeEnd: [3]), at: start)
        XCTAssertEqual(s.nudges.map(\.taps), [2])
    }

    func testNoZeroNudge() {
        let s = ActiveSession.start(SessionPreset(name: "M", durationMinutes: 45, nudgeMinutesBeforeEnd: [15, 10, 5]), at: start)
        XCTAssertEqual(s.nudges.map(\.taps), [1, 1, 2])
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
        XCTAssertEqual(s.upcomingNudges(after: t).map(\.minutesLeft), [5, 0])
        XCTAssertEqual(s.nextNudge(after: t)?.minutesLeft, 5)
        XCTAssertNil(s.nextNudge(after: s.endDate))
        XCTAssertFalse(s.isFinished(at: t))
        XCTAssertTrue(s.isFinished(at: s.endDate))
    }

    func testDueNudgesSkipsStaleAndDelivered() {
        let s = ActiveSession.start(SessionPreset(name: "M", durationMinutes: 30, nudgeMinutesBeforeEnd: [10, 5, 0]), at: start)
        let at10 = s.nudges[0].fireDate
        XCTAssertEqual(s.dueNudges(at: at10, delivered: []).map(\.minutesLeft), [10])
        XCTAssertEqual(s.dueNudges(at: at10.addingTimeInterval(-0.1), delivered: []).count, 0)
        XCTAssertEqual(s.dueNudges(at: at10, delivered: [s.nudges[0].id]).count, 0)
        XCTAssertEqual(s.dueNudges(at: at10.addingTimeInterval(31), delivered: []).count, 0, "stale nudge must not replay")
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
            played += tracker.takeDue(at: t).map(\.minutesLeft)
            t = t.addingTimeInterval(0.5)
        }
        XCTAssertEqual(played, [5, 0])
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
        XCTAssertFalse(tracker.claim(nudgeID: "nudgy.unknown.5"))
    }

    func testLateSyncMarksPastNudgesDelivered() {
        var tracker = NudgeTracker()
        let s = ActiveSession.start(SessionPreset(name: "M", durationMinutes: 30, nudgeMinutesBeforeEnd: [25, 5]), at: start)
        tracker.begin(s, now: start.addingTimeInterval(10 * 60))
        XCTAssertEqual(tracker.delivered, [s.nudges[0].id])
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

    func testCountdown() {
        XCTAssertEqual(CountdownFormatter.string(2700), "45:00")
        XCTAssertEqual(CountdownFormatter.string(245), "4:05")
        XCTAssertEqual(CountdownFormatter.string(3900), "1:05:00")
        XCTAssertEqual(CountdownFormatter.string(0.4), "0:01", "rounds up while counting down")
        XCTAssertEqual(CountdownFormatter.string(0), "0:00")
        XCTAssertEqual(CountdownFormatter.string(-30.7), "+0:30")
    }

    func testSyncMessageRoundTrip() throws {
        let s = ActiveSession.start(SessionPreset.defaults[1], at: Date(timeIntervalSince1970: 3_000_000))
        for msg in [SyncMessage.start(s), .stop(sessionID: s.id), .presets(SessionPreset.defaults)] {
            XCTAssertEqual(SyncMessage.decode(try msg.encoded()), msg)
        }
        XCTAssertNil(SyncMessage.decode(["other": 1]))
        XCTAssertNil(SyncMessage.decode([SyncMessage.payloadKey: Data("junk".utf8)]))
    }
}
