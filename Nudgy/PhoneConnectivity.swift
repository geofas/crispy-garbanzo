import Foundation
import WatchConnectivity
import NudgyKit

/// iPhone side of iPhone ↔ Watch sync.
final class PhoneConnectivity: NSObject, WCSessionDelegate {
    var onMessage: (@MainActor (SyncMessage) -> Void)?
    var onActivated: (@MainActor () -> Void)?

    private var session: WCSession? { WCSession.isSupported() ? WCSession.default : nil }

    func activate() {
        session?.delegate = self
        session?.activate()
    }

    /// A paired Apple Watch with Nudgy installed.
    var watchAvailable: Bool {
        guard let s = session, s.activationState == .activated else { return false }
        return s.isPaired && s.isWatchAppInstalled
    }

    func send(_ message: SyncMessage) {
        guard let s = session, s.activationState == .activated, s.isPaired, s.isWatchAppInstalled,
              let payload = try? message.encoded() else { return }
        if s.isReachable {
            s.sendMessage(payload, replyHandler: nil) { _ in
                // Fall back to queued delivery if the live message fails.
                s.transferUserInfo(payload)
            }
        } else {
            s.transferUserInfo(payload)
        }
    }

    func pushPresets(_ presets: [SessionPreset]) {
        guard let s = session, s.activationState == .activated, s.isPaired, s.isWatchAppInstalled,
              let payload = try? SyncMessage.presets(presets).encoded() else { return }
        try? s.updateApplicationContext(payload)
    }

    // MARK: WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        guard activationState == .activated else { return }
        Task { @MainActor in self.onActivated?() }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        // Required when the user switches to a different watch.
        session.activate()
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        deliver(message)
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        deliver(userInfo)
    }

    private func deliver(_ dictionary: [String: Any]) {
        guard let message = SyncMessage.decode(dictionary) else { return }
        Task { @MainActor in self.onMessage?(message) }
    }
}
