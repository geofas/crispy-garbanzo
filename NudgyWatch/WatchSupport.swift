import Foundation
import WatchKit
import NudgyKit

/// Distinct tap patterns on the wrist.
enum WatchHaptics {
    static func play(taps: Int) {
        Task { @MainActor in
            for i in 0..<max(1, taps) {
                WKInterfaceDevice.current().play(.notification)
                if i < taps - 1 {
                    try? await Task.sleep(nanoseconds: 900_000_000)
                }
            }
        }
    }
}

/// Wraps the extended runtime session (Mindfulness type, set in WKBackgroundModes).
/// It keeps Nudgy running with the wrist down, for up to 1 hour, as long as the user
/// does not leave the app. After that, backup notifications take over.
final class RuntimeSession: NSObject, WKExtendedRuntimeSessionDelegate {
    var onStateChange: (@MainActor (Bool) -> Void)?
    private var session: WKExtendedRuntimeSession?

    func start() {
        if let s = session, s.state == .running || s.state == .scheduled { return }
        let s = WKExtendedRuntimeSession()
        s.delegate = self
        session = s
        s.start()
    }

    func stop() {
        session?.invalidate()
        session = nil
    }

    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        Task { @MainActor in self.onStateChange?(true) }
    }

    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {}

    func extendedRuntimeSession(
        _ extendedRuntimeSession: WKExtendedRuntimeSession,
        didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
        error: Error?
    ) {
        Task { @MainActor in
            if self.session === extendedRuntimeSession { self.session = nil }
            self.onStateChange?(false)
        }
    }
}
