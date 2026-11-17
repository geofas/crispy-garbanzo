import Foundation
import WatchConnectivity
import NudgyKit

/// iPhone ↔ Watch sync, used by both apps.
final class PeerConnectivity: NSObject, WCSessionDelegate {
    var onMessage: (@MainActor (SyncMessage) -> Void)?
    /// Called when the connection becomes active or the paired-watch state changes.
    var onActivated: (@MainActor () -> Void)?

    private var session: WCSession? { WCSession.isSupported() ? WCSession.default : nil }

    func activate() {
        session?.delegate = self
        session?.activate()
    }

    /// The other device has Nudgy installed (and, on iPhone, a Watch is paired).
    var peerAvailable: Bool {
        guard let s = session, s.activationState == .activated else { return false }
        #if os(iOS)
        return s.isPaired && s.isWatchAppInstalled
        #else
        return s.isCompanionAppInstalled
        #endif
    }

    func send(_ message: SyncMessage) {
        guard peerAvailable, let s = session, let payload = try? message.encoded() else { return }
        if s.isReachable {
            s.sendMessage(payload, replyHandler: nil) { _ in
                // Fall back to queued delivery if the live message fails.
                s.transferUserInfo(payload)
            }
        } else {
            s.transferUserInfo(payload)
        }
    }

    /// Latest-value sync: the Watch receives the current timers and theme whenever it next connects.
    func pushAppState(presets: [SessionPreset], theme: Theme) {
        guard peerAvailable, let s = session,
              let payload = try? SyncMessage.appState(presets: presets, theme: theme).encoded() else { return }
        try? s.updateApplicationContext(payload)
    }

    // MARK: WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        guard activationState == .activated else { return }
        deliver(session.receivedApplicationContext)
        Task { @MainActor in self.onActivated?() }
    }

    #if os(iOS)
    func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in self.onActivated?() }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        // Required when the user switches to a different watch.
        session.activate()
    }
    #endif

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
