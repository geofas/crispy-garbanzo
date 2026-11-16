import Foundation
import SwiftUI
import WatchKit
import NudgyKit

/// Watch app state: the timers the iPhone allows (it applies the free/paid rule), the shared session engine, and the runtime session
/// that keeps Nudgy running with the wrist down.
@MainActor
final class WatchModel: ObservableObject {
    @Published private(set) var presets: [SessionPreset]
    /// True while the extended runtime session is running, i.e. Nudgy plays nudges itself
    /// with the wrist down. False means only the backup notifications are active.
    @Published private(set) var patternsActive = false

    let engine: SessionEngine
    private let connectivity: PeerConnectivity
    private let runtime = RuntimeSession()

    init() {
        let connectivity = PeerConnectivity()
        self.connectivity = connectivity
        // Until the iPhone has sent its list, offer the free timers.
        presets = SessionStore.loadPresets() ?? Catalog.available(templates: Catalog.templates, custom: [], unlocked: false)
        engine = SessionEngine(platform: .init(
            delivers: { $0.target != .phone },
            peerShouldKnow: { _ in true },
            play: { WatchHaptics.play() },
            send: { connectivity.send($0) }
        ))

        engine.onPresets = { [weak self] list in
            self?.presets = list
            SessionStore.savePresets(list)
        }
        engine.onSessionBegan = { [weak self] in self?.startRuntimeIfNeeded() }
        engine.onSessionEnded = { [weak self] in self?.runtime.stop() }
        engine.onNudgesFinished = { [weak self] in self?.releaseRuntimeSoon() }
        runtime.onStateChange = { [weak self] running in self?.patternsActive = running }
        connectivity.onMessage = { [weak self] message in self?.engine.handle(message) }
        connectivity.activate()
    }

    func didBecomeActive() {
        engine.requestNotificationPermission()
        engine.didBecomeActive()
        startRuntimeIfNeeded()
    }

    /// The runtime session can only start while the app is active on screen.
    private func startRuntimeIfNeeded() {
        guard let session = engine.active, engine.delivering,
              session.nextNudge(after: Date()) != nil else { return }
        guard WKApplication.shared().applicationState == .active else { return }
        runtime.start()
    }

    /// Releases the runtime session shortly after the last nudge, to save battery.
    /// The delay lets the last nudge finish first.
    private func releaseRuntimeSoon() {
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            guard let self else { return }
            if self.engine.active?.nextNudge(after: Date()) == nil {
                self.runtime.stop()
            }
        }
    }
}
