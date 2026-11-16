import Foundation
import NudgyKit

/// Small on-device persistence (UserDefaults + JSON). Nothing leaves the device
/// except iPhone ↔ Watch sync.
enum SessionStore {
    private static let presetsKey = "nudgy.presets.v1"
    private static let activeKey = "nudgy.activeSession.v1"
    private static var defaults: UserDefaults { .standard }

    static func loadPresets() -> [SessionPreset]? {
        guard let data = defaults.data(forKey: presetsKey) else { return nil }
        return try? JSONDecoder().decode([SessionPreset].self, from: data)
    }

    static func savePresets(_ presets: [SessionPreset]) {
        defaults.set(try? JSONEncoder().encode(presets), forKey: presetsKey)
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
