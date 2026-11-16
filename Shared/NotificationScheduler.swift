import Foundation
import UserNotifications
import NudgyKit

/// Schedules *backup* notifications for nudges (iPhone and Watch).
///
/// The in-app timer plays each nudge on time and cancels its backup. A backup only
/// reaches the user if the app was suspended, which on the Watch is whenever the wrist is down.
final class NotificationScheduler: NSObject, UNUserNotificationCenterDelegate {
    /// Called on the main actor when a backup notification arrives while the app is in the foreground.
    var onForegroundNudge: (@MainActor (String) -> Void)?

    private let center = UNUserNotificationCenter.current()

    override init() {
        super.init()
        center.delegate = self
    }

    func requestAuthorization() {
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    /// Session whose backups are wanted. Main thread only.
    private var wantedSessionID: UUID?

    /// Asks for permission if needed, then schedules. Nothing is scheduled before the
    /// user has answered the prompt, or if the session was stopped in the meantime.
    func scheduleBackups(for session: ActiveSession) {
        wantedSessionID = session.id
        center.requestAuthorization(options: [.alert, .sound]) { [weak self] granted, _ in
            guard granted else { return }
            DispatchQueue.main.async {
                guard let self, self.wantedSessionID == session.id else { return }
                self.addBackups(for: session, now: Date())
            }
        }
    }

    private func addBackups(for session: ActiveSession, now: Date) {
        for nudge in session.nudges where nudge.fireDate > now {
            let content = UNMutableNotificationContent()
            content.title = nudge.message
            content.body = session.presetName
            content.threadIdentifier = session.id.uuidString
            #if os(iOS)
            // Same ding as in the app. In Silent Mode the iPhone only vibrates.
            content.sound = UNNotificationSound(named: UNNotificationSoundName("ding.wav"))
            content.interruptionLevel = .timeSensitive
            #else
            content.sound = .default
            #endif
            let fire = nudge.fireDate.addingTimeInterval(backupNotificationDelay)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, fire.timeIntervalSince(now)), repeats: false)
            center.add(UNNotificationRequest(identifier: nudge.id, content: content, trigger: trigger))
        }
    }

    func cancelBackup(id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
    }

    /// Removes backups that have not fired yet (used when delivery moves to the other device).
    func cancelPending(for session: ActiveSession) {
        wantedSessionID = nil
        center.removePendingNotificationRequests(withIdentifiers: session.nudges.map(\.id))
    }

    func cancelAll(for session: ActiveSession) {
        wantedSessionID = nil
        let ids = session.nudges.map(\.id)
        center.removePendingNotificationRequests(withIdentifiers: ids)
        center.removeDeliveredNotifications(withIdentifiers: ids)
    }

    /// IDs of nudge notifications the system has already shown (so the app does not replay them).
    func deliveredNudgeIDs(_ completion: @escaping @Sendable ([String]) -> Void) {
        center.getDeliveredNotifications { notifications in
            completion(notifications.map(\.request.identifier))
        }
    }

    // MARK: UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let id = notification.request.identifier
        // In the foreground the app plays its own discreet haptic instead of a banner/sound.
        completionHandler([])
        Task { @MainActor in self.onForegroundNudge?(id) }
    }
}
