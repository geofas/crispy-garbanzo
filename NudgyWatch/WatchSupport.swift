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
        // Keep any session that has not ended. `start()` is asynchronous, so a session
        // can still read as "not started" just after it was started; replacing it then
        // would throw away a session that is about to run.
        if let s = session, s.state != .invalid { return }
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
        Task { @MainActor in
            guard self.session === extendedRuntimeSession else { return }
            self.onStateChange?(true)
        }
    }

    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {}

    func extendedRuntimeSession(
        _ extendedRuntimeSession: WKExtendedRuntimeSession,
        didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
        error: Error?
    ) {
        Task { @MainActor in
            // Only the current session changes the state shown on screen.
            guard self.session === extendedRuntimeSession else { return }
            self.session = nil
            self.onStateChange?(false)
        }
    }
}
