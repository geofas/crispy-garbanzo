import Foundation

/// Decides which device(s) actually deliver nudges.
public struct DeliveryPlan: Equatable, Sendable {
    public var phone: Bool
    public var watch: Bool

    public init(phone: Bool, watch: Bool) {
        self.phone = phone
        self.watch = watch
    }

    /// - Parameter watchAvailable: a paired watch with Nudgy installed.
    /// If the user chose the watch but none is available, the phone takes over so no nudge is lost.
    public static func resolve(target: NudgeTarget, watchAvailable: Bool) -> DeliveryPlan {
        switch target {
        case .phone:
            return DeliveryPlan(phone: true, watch: false)
        case .watch:
            return watchAvailable ? DeliveryPlan(phone: false, watch: true) : DeliveryPlan(phone: true, watch: false)
        case .both:
            return DeliveryPlan(phone: true, watch: watchAvailable)
        }
    }
}

extension DeliveryPlan {
    /// Text for "Nudging on: …".
    public var label: String {
        switch (phone, watch) {
        case (true, true): return "Watch + iPhone"
        case (false, true): return "Apple Watch"
        default: return "iPhone"
        }
    }
}

/// Seconds a backup notification fires after its nominal time. The in-app timer fires on
/// time and cancels the backup; the backup only appears if the app was suspended.
public let backupNotificationDelay: TimeInterval = 2

/// Formats a countdown: "4:05", "45:00", "1:05:00"; overruns as "+0:30".
public enum CountdownFormatter {
    public static func string(_ seconds: TimeInterval) -> String {
        let overrun = seconds < 0
        let total = Int(abs(seconds).rounded(overrun ? .down : .up))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        let body = h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%d:%02d", m, s)
        return overrun ? "+" + body : body
    }
}

/// Messages exchanged between iPhone and Watch.
public enum SyncMessage: Codable, Equatable, Sendable {
    case start(ActiveSession)
    case stop(sessionID: UUID)
    case presets([SessionPreset])

    public static let payloadKey = "nudgyPayload"

    public func encoded() throws -> [String: Any] {
        [Self.payloadKey: try JSONEncoder().encode(self)]
    }

    public static func decode(_ dictionary: [String: Any]) -> SyncMessage? {
        guard let data = dictionary[payloadKey] as? Data else { return nil }
        return try? JSONDecoder().decode(SyncMessage.self, from: data)
    }
}
