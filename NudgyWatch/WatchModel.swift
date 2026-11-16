import Foundation
import SwiftUI
import WatchKit
import NudgyKit

@MainActor
final class WatchModel: ObservableObject {
    @Published private(set) var presets: [SessionPreset]
    @Published private(set) var active: ActiveSession?
    @Published private(set) var now = Date()
    /// True while the extended runtime session is running, i.e. distinct tap patterns
    /// play with the wrist down. False means only the backup notifications are active.
    @Published private(set) var patternsActive = false

    private var tracker = NudgeTracker()
    private var watchDelivers = false
    private var timer: Timer?

    private let notifier = NotificationScheduler()
    private let connectivity = WatchConnectivity()
    private let runtime = RuntimeSession()

    init() {
        presets = SessionStore.loadPresets() ?? SessionPreset.defaults

        notifier.onForegroundNudge = { [weak self] id in self?.playFromBackup(id: id) }
        connectivity.onMessage = { [weak self] message in self?.handle(message) }
        runtime.onStateChange = { [weak self] running in self?.patternsActive = running }
        connectivity.activate()

        if let saved = SessionStore.loadActive() {
            if !saved.isExpired(at: Date()) {
                restore(saved)
            } else {
                SessionStore.saveActive(nil)
            }
        }
    }

    // MARK: Session lifecycle

    func start(_ preset: SessionPreset) {
        let session = ActiveSession.start(preset, at: Date())
        begin(session)
        connectivity.send(.start(session))
    }

    func stop() {
        guard let session = active else { return }
        notifier.cancelAll(for: session)
        connectivity.send(.stop(sessionID: session.id))
        clear()
    }

    func didBecomeActive() {
        now = Date()
        notifier.requestAuthorization()
        notifier.deliveredNudgeIDs { ids in
            Task { @MainActor [weak self] in
                for id in ids { _ = self?.tracker.claim(nudgeID: id) }
            }
        }
        startRuntimeIfNeeded()
    }

    // MARK: Private

    private func begin(_ session: ActiveSession) {
        if active?.id == session.id { return }
        if let old = active { notifier.cancelAll(for: old) }

        watchDelivers = session.target != .phone
        active = session
        tracker.begin(session, now: Date())
        SessionStore.saveActive(session)

        if watchDelivers { notifier.scheduleBackups(for: session) }
        startTicking()
        startRuntimeIfNeeded()
    }

    private func restore(_ session: ActiveSession) {
        watchDelivers = session.target != .phone
        active = session
        tracker.begin(session, now: Date())
        startTicking()
    }

    private func clear() {
        timer?.invalidate()
        timer = nil
        runtime.stop()
        active = nil
        tracker.end()
        SessionStore.saveActive(nil)
    }

    private func handle(_ message: SyncMessage) {
        switch message {
        case .start(let session):
            guard session.endDate > Date() else { return }
            begin(session)
        case .stop(let id):
            guard let session = active, session.id == id else { return }
            notifier.cancelAll(for: session)
            clear()
        case .presets(let list):
            presets = list
            SessionStore.savePresets(list)
        }
    }

    /// The runtime session can only start while the app is active on screen.
    private func startRuntimeIfNeeded() {
        guard let session = active, watchDelivers, !session.isFinished(at: Date()) else { return }
        guard WKApplication.shared().applicationState == .active else { return }
        runtime.start()
    }

    private func startTicking() {
        timer?.invalidate()
        let t = Timer(timeInterval: 0.5, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
        tick()
    }

    private func tick() {
        now = Date()
        guard let session = active else { return }
        if session.isExpired(at: now) {
            notifier.cancelAll(for: session)
            clear()
            return
        }
        if watchDelivers {
            for nudge in tracker.takeDue(at: now) {
                notifier.cancelBackup(id: nudge.id)
                WatchHaptics.play(taps: nudge.taps)
            }
        }
        // Release the runtime session shortly after the last nudge to save battery.
        if session.upcomingNudges(after: now).isEmpty, session.isFinished(at: now.addingTimeInterval(-5)) {
            runtime.stop()
        }
    }

    private func playFromBackup(id: String) {
        guard let nudge = active?.nudges.first(where: { $0.id == id }) else { return }
        if tracker.claim(nudgeID: id) {
            WatchHaptics.play(taps: nudge.taps)
        }
    }
}
