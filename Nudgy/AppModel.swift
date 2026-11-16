import Foundation
import SwiftUI
import NudgyKit

/// iPhone app state: presets, plus the shared session engine.
@MainActor
final class AppModel: ObservableObject {
    @Published var presets: [SessionPreset] {
        didSet {
            SessionStore.savePresets(presets)
            connectivity.pushPresets(presets)
        }
    }

    let engine: SessionEngine
    private let connectivity: PeerConnectivity

    init() {
        let connectivity = PeerConnectivity()
        self.connectivity = connectivity
        presets = SessionStore.loadPresets() ?? SessionPreset.defaults
        engine = SessionEngine(platform: .init(
            delivers: { DeliveryPlan.resolve(target: $0.target, watchAvailable: connectivity.peerAvailable).phone },
            peerShouldKnow: { DeliveryPlan.resolve(target: $0.target, watchAvailable: connectivity.peerAvailable).watch },
            play: { PhoneHaptics.play(taps: $0) },
            send: { connectivity.send($0) }
        ))

        connectivity.onMessage = { [weak self] message in self?.engine.handle(message) }
        connectivity.onActivated = { [weak self] in
            guard let self else { return }
            self.connectivity.pushPresets(self.presets)
            self.engine.reconcile()
        }
        connectivity.activate()
    }

    /// A paired Apple Watch with Nudgy installed.
    var watchAvailable: Bool { connectivity.peerAvailable }

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

    /// Lets the user feel a pattern on the iPhone.
    func preview(taps: Int) {
        PhoneHaptics.play(taps: taps)
    }
}
