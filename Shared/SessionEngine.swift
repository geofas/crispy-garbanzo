import Foundation
import NudgyKit

/// Runs a session on one device: bookkeeping, backup notifications, timing and sync.
/// The iPhone and the Watch each own one engine and differ only in `Platform`.
@MainActor
final class SessionEngine: ObservableObject {
    /// What differs between iPhone and Watch.
    struct Platform {
        /// Does this device deliver the nudges for the session?
        var delivers: @MainActor (ActiveSession) -> Bool
        /// Should the other device be told about the session?
        var peerShouldKnow: @MainActor (ActiveSession) -> Bool
        /// Play one nudge (sound and vibration) on this device.
        var play: @MainActor () -> Void
        /// Send a message to the other device.
        var send: @MainActor (SyncMessage) -> Void
    }

    @Published private(set) var active: ActiveSession?
    /// Whether this device is the one delivering nudges for `active`.
    @Published private(set) var delivering = false
    /// Goes up by one each time this device plays a nudge. The screen flashes white on change.
    @Published private(set) var nudgeFlash = 0

    var onSessionBegan: (() -> Void)?
    var onSessionEnded: (() -> Void)?
    /// Called whenever the engine wakes and no nudges remain.
    var onNudgesFinished: (() -> Void)?
    var onPresets: (([SessionPreset]) -> Void)?

    private let platform: Platform
    private let notifier = NotificationScheduler()
    private var tracker = NudgeTracker()
    private var peerInformed = false
    private var timer: Timer?

    init(platform: Platform) {
        self.platform = platform
        notifier.onForegroundNudge = { [weak self] id in self?.playFromBackup(id: id) }

        // Restore a session that was running when the app was terminated.
        if let saved = SessionStore.loadActive() {
            if saved.isExpired(at: Date()) {
                SessionStore.saveActive(nil)
            } else {
                active = saved
                // Use the decision saved at start; `reconcile()` corrects it if needed.
                delivering = SessionStore.loadDelivers() ?? platform.delivers(saved)
                tracker.begin(saved, now: Date())
                scheduleWake()
            }
        }
    }

    // MARK: Commands

    func start(_ preset: SessionPreset) {
        begin(ActiveSession.start(preset, at: Date()), originatedHere: true)
    }

    func stop() {
        guard let session = active else { return }
        notifier.cancelAll(for: session)
        platform.send(.stop(sessionID: session.id))
        clear()
    }

    func requestNotificationPermission() {
        notifier.requestAuthorization()
    }

    func didBecomeActive() {
        // Nudges the system already showed while the app was suspended must not replay.
        notifier.deliveredNudgeIDs { [weak self] ids in
            Task { @MainActor in
                guard let self else { return }
                for id in ids { _ = self.tracker.claim(nudgeID: id) }
                self.processDue()
            }
        }
    }

    /// Re-evaluates which device delivers. The iPhone calls this once the Watch connection
    /// is active, because the first decision can be made before that is known.
    func reconcile() {
        guard let session = active, !session.isFinished(at: Date()) else { return }
        let delivers = platform.delivers(session)
        if delivers != delivering {
            delivering = delivers
            SessionStore.saveDelivers(delivers)
            if delivers {
                notifier.scheduleBackups(for: session)
            } else {
                notifier.cancelPending(for: session)
            }
        }
        if !peerInformed && platform.peerShouldKnow(session) {
            platform.send(.start(session))
            peerInformed = true
        }
    }

    func handle(_ message: SyncMessage) {
        switch message {
        case .start(let session):
            guard session.endDate > Date() else { return } // stale queued message
            begin(session, originatedHere: false)
        case .stop(let id):
            guard let session = active, session.id == id else { return }
            notifier.cancelAll(for: session)
            clear()
        case .presets(let list):
            onPresets?(list)
        }
    }

    // MARK: Private

    private func begin(_ session: ActiveSession, originatedHere: Bool) {
        if active?.id == session.id { return } // duplicate delivery of the same start
        if let old = active { notifier.cancelAll(for: old) }

        let delivers = platform.delivers(session)
        active = session
        delivering = delivers
        tracker.begin(session, now: Date())
        SessionStore.saveActive(session)
        SessionStore.saveDelivers(delivers)

        if delivers { notifier.scheduleBackups(for: session) }
        if originatedHere {
            peerInformed = platform.peerShouldKnow(session)
            if peerInformed { platform.send(.start(session)) }
        } else {
            peerInformed = true
        }
        scheduleWake()
        onSessionBegan?()
    }

    private func clear() {
        timer?.invalidate()
        timer = nil
        active = nil
        delivering = false
        tracker.end()
        SessionStore.saveActive(nil)
        onSessionEnded?()
    }

    /// Plays whatever is due, then sleeps until the next nudge (or expiry).
    private func processDue() {
        guard let session = active else { return }
        let now = Date()
        if session.isExpired(at: now) {
            notifier.cancelAll(for: session)
            clear()
            return
        }
        if delivering {
            for nudge in tracker.takeDue(at: now) {
                notifier.cancelBackup(id: nudge.id)
                platform.play()
                nudgeFlash += 1
            }
        }
        if session.upcomingNudges(after: now).isEmpty { onNudgesFinished?() }
        scheduleWake()
    }

    /// One timer per event instead of polling.
    private func scheduleWake() {
        timer?.invalidate()
        timer = nil
        guard let wake = tracker.nextWakeDate(after: Date()) else { return }
        let t = Timer(fire: wake, interval: 0, repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.processDue() }
        }
        t.tolerance = 0
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func playFromBackup(id: String) {
        guard active?.nudges.contains(where: { $0.id == id }) == true else { return }
        if tracker.claim(nudgeID: id) {
            platform.play()
            nudgeFlash += 1
        }
    }
}
