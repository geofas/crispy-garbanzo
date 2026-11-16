import Foundation

/// The app's look. Basic is free; the two designed themes come with the one-time unlock.
public enum Theme: String, Codable, CaseIterable, Identifiable, Hashable, Sendable {
    /// Standard iOS look (system colours). The default for every new user.
    case basic
    /// Dark, with an amber accent.
    case quietSignal
    /// Light, with a violet accent.
    case friendlyTap

    public var id: String { rawValue }

    public var name: String {
        switch self {
        case .basic: return "Basic"
        case .quietSignal: return "Quiet Signal"
        case .friendlyTap: return "Friendly Tap"
        }
    }

    public var summary: String {
        switch self {
        case .basic: return "Standard iPhone look"
        case .quietSignal: return "Dark, amber accent"
        case .friendlyTap: return "Light, violet accent"
        }
    }

    public var isFree: Bool { self == .basic }

    /// Whether the user may use this theme.
    public func isAvailable(unlocked: Bool) -> Bool {
        unlocked || isFree
    }

    /// The theme actually shown: the user's choice, or Basic if that choice needs the unlock
    /// and the user does not have it (for example after a refund).
    public static func effective(selected: Theme, unlocked: Bool) -> Theme {
        selected.isAvailable(unlocked: unlocked) ? selected : .basic
    }

    /// Name of the alternate iPhone app icon for this theme; nil means the primary icon.
    /// Must match the icon sets in the asset catalog and the
    /// ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES build setting.
    public var alternateIconName: String? {
        switch self {
        case .basic: return nil
        case .quietSignal: return "AppIcon-QuietSignal"
        case .friendlyTap: return "AppIcon-FriendlyTap"
        }
    }
}
