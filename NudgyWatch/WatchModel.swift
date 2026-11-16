import Foundation
import SwiftUI
import NudgyKit

/// Watch app state: the timers the iPhone allows (it applies the free/paid rule) and the
/// shared session engine. With the wrist down, nudges arrive as scheduled notifications;
/// while Nudgy is on screen it plays them itself, with the white flash.
@MainActor
final class WatchModel: ObservableObject {
    @Published private(set) var presets: [SessionPreset]

    let engine: SessionEngine
    private let connectivity: PeerConnectivity

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
        connectivity.onMessage = { [weak self] message in self?.engine.handle(message) }
        connectivity.activate()
    }

    func didBecomeActive() {
        engine.requestNotificationPermission()
        engine.didBecomeActive()
    }
}
