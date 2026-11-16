import Foundation
import NudgyKit

/// Small on-device persistence (UserDefaults + JSON). Nothing leaves the device
/// except iPhone ↔ Watch sync.
enum SessionStore {
    // v2: nudges are stored in seconds and timers can repeat.
    private static let presetsKey = "nudgy.presets.v2"
    private static let templatesKey = "nudgy.templates.v1"
    private static let activeKey = "nudgy.activeSession.v2"
    private static var defaults: UserDefaults { .standard }

    /// iPhone: the timers the user created. Watch: the timers the iPhone last sent.
    static func loadPresets() -> [SessionPreset]? {
        guard let data = defaults.data(forKey: presetsKey) else { return nil }
        return try? JSONDecoder().decode([SessionPreset].self, from: data)
    }

    static func savePresets(_ presets: [SessionPreset]) {
        defaults.set(try? JSONEncoder().encode(presets), forKey: presetsKey)
    }

    /// Built-in timers as last saved (only their repeat on/off choice is used).
    static func loadTemplates() -> [SessionPreset] {
        guard let data = defaults.data(forKey: templatesKey) else { return [] }
        return (try? JSONDecoder().decode([SessionPreset].self, from: data)) ?? []
    }

    static func saveTemplates(_ templates: [SessionPreset]) {
        defaults.set(try? JSONEncoder().encode(templates), forKey: templatesKey)
    }

    private static let deliversKey = "nudgy.delivers.v1"

    /// Whether this device delivers nudges for the saved session (nil if never saved).
    static func loadDelivers() -> Bool? {
        defaults.object(forKey: deliversKey) as? Bool
    }

    static func saveDelivers(_ value: Bool) {
        defaults.set(value, forKey: deliversKey)
    }

    static func loadActive() -> ActiveSession? {
        guard let data = defaults.data(forKey: activeKey) else { return nil }
        return try? JSONDecoder().decode(ActiveSession.self, from: data)
    }

    static func saveActive(_ session: ActiveSession?) {
        if let session {
            defaults.set(try? JSONEncoder().encode(session), forKey: activeKey)
        } else {
            defaults.removeObject(forKey: activeKey)
        }
    }
}
