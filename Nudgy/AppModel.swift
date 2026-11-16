import Foundation
import SwiftUI
import NudgyKit

@MainActor
final class AppModel: ObservableObject {
    @Published var presets: [SessionPreset] {
        didSet {
            SessionStore.savePresets(presets)
            connectivity.pushPresets(presets)
        }
    }
    @Published private(set) var active: ActiveSession?
    @Published private(set) var now = Date()

    private var tracker = NudgeTracker()
    private var phoneDelivers = false
    /// Whether the Watch has been told about the current session.
    private var watchInformed = false
    private var timer: Timer?

    private let notifier = NotificationScheduler()
    private let connectivity = PhoneConnectivity()

    init() {
        presets = SessionStore.loadPresets() ?? SessionPreset.defaults

        notifier.onForegroundNudge = { [weak self] id in self?.playFromBackup(id: id) }
        connectivity.onMessage = { [weak self] message in self?.handle(message) }
        connectivity.onActivated = { [weak self] in
            guard let self else { return }
            self.connectivity.pushPresets(self.presets)
            self.reconcileDelivery()
        }
        connectivity.activate()

        if let saved = SessionStore.loadActive() {
            if saved.isExpired(at: Date()) {
                SessionStore.saveActive(nil)
            } else {
                resume(saved)
            }
        }
    }

    // MARK: Presets

    func save(_ preset: SessionPreset) {
        let p = preset.normalized()
        if let i = presets.firstIndex(where: { $0.id == p.id }) {
            presets[i] = p
        } else {
            presets.append(p)
        }
    }

    func delete(at offsets: IndexSet) {
        presets.remove(atOffsets: offsets)
    }

    // MARK: Session lifecycle

    func start(_ preset: SessionPreset) {
        begin(ActiveSession.start(preset, at: Date()), originatedHere: true)
    }

    func stop() {
        guard let session = active else { return }
        notifier.cancelAll(for: session)
        connectivity.send(.stop(sessionID: session.id))
        clear()
    }

    func didBecomeActive() {
        now = Date()
        // Nudges the system already showed while we were suspended must not replay.
        notifier.deliveredNudgeIDs { ids in
            Task { @MainActor [weak self] in
                for id in ids { _ = self?.tracker.claim(nudgeID: id) }
            }
        }
    }

    /// Lets the user feel a pattern on the iPhone.
    func preview(taps: Int) {
        PhoneHaptics.play(taps: taps)
    }

    var watchAvailable: Bool { connectivity.watchAvailable }

    // MARK: Private

    private func begin(_ session: ActiveSession, originatedHere: Bool) {
        if active?.id == session.id { return } // duplicate delivery of the same start
        if let old = active { notifier.cancelAll(for: old) }

        let plan = DeliveryPlan.resolve(target: session.target, watchAvailable: connectivity.watchAvailable)
        phoneDelivers = plan.phone
        active = session
        tracker.begin(session, now: Date())
        SessionStore.saveActive(session)
        SessionStore.savePhoneDelivers(plan.phone)

        if plan.phone { notifier.scheduleBackups(for: session) }
        if originatedHere && plan.watch { connectivity.send(.start(session)) }
        watchInformed = !originatedHere || plan.watch
        startTicking()
    }

    /// The Watch connection activates shortly after launch, so the first delivery decision
    /// can be made without knowing about the Watch. This corrects it once the facts are in.
    private func reconcileDelivery() {
        guard let session = active, !session.isFinished(at: Date()) else { return }
        let plan = DeliveryPlan.resolve(target: session.target, watchAvailable: connectivity.watchAvailable)
        if plan.phone != phoneDelivers {
            phoneDelivers = plan.phone
            SessionStore.savePhoneDelivers(plan.phone)
            if plan.phone {
                notifier.scheduleBackups(for: session)
            } else {
                notifier.cancelPending(for: session)
            }
        }
        if plan.watch && !watchInformed {
            connectivity.send(.start(session))
            watchInformed = true
        }
    }

    /// Restores a session after the app was terminated and relaunched.
    private func resume(_ session: ActiveSession) {
        // Use the decision saved when the session started; `reconcileDelivery` corrects it if needed.
        phoneDelivers = SessionStore.loadPhoneDelivers() ?? true
        watchInformed = false
        active = session
        tracker.begin(session, now: Date())
        startTicking()
    }

    private func clear() {
        timer?.invalidate()
        timer = nil
        active = nil
        tracker.end()
        SessionStore.saveActive(nil)
    }

    private func handle(_ message: SyncMessage) {
        switch message {
        case .start(let session):
            guard session.endDate > Date() else { return } // stale queued message
            begin(session, originatedHere: false)
        case .stop(let id):
            guard let session = active, session.id == id else { return }
            notifier.cancelAll(for: session)
            clear()
        case .presets:
            break // the iPhone is the source of truth for presets
        }
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
        if let session = active, session.isExpired(at: now) {
            notifier.cancelAll(for: session)
            clear()
            return
        }
        guard phoneDelivers else { return }
        for nudge in tracker.takeDue(at: now) {
            notifier.cancelBackup(id: nudge.id)
            PhoneHaptics.play(taps: nudge.taps)
        }
    }

    private func playFromBackup(id: String) {
        guard let nudge = active?.nudges.first(where: { $0.id == id }) else { return }
        if tracker.claim(nudgeID: id) {
            PhoneHaptics.play(taps: nudge.taps)
        }
    }
}
