import Foundation
import WatchKit
import WatchConnectivity
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

/// Watch side of iPhone ↔ Watch sync.
final class WatchConnectivity: NSObject, WCSessionDelegate {
    var onMessage: (@MainActor (SyncMessage) -> Void)?
    private var session: WCSession { WCSession.default }

    func activate() {
        session.delegate = self
        session.activate()
    }

    func send(_ message: SyncMessage) {
        guard session.activationState == .activated, let payload = try? message.encoded() else { return }
        let s = session
        if s.isReachable {
            s.sendMessage(payload, replyHandler: nil) { _ in
                s.transferUserInfo(payload)
            }
        } else {
            s.transferUserInfo(payload)
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        guard activationState == .activated else { return }
        deliver(session.receivedApplicationContext)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        deliver(message)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        deliver(userInfo)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        deliver(applicationContext)
    }

    private func deliver(_ dictionary: [String: Any]) {
        guard let message = SyncMessage.decode(dictionary) else { return }
        Task { @MainActor in self.onMessage?(message) }
    }
}
