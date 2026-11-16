import Foundation
import SwiftUI
import UIKit
import NudgyKit

/// iPhone app state: the timers, the free/paid rule, plus the shared session engine.
@MainActor
final class AppModel: ObservableObject {
    /// Built-in timers. Only their repeat on/off choice can change.
    @Published private(set) var templates: [SessionPreset]
    /// Timers the user created (needs the unlock).
    @Published private(set) var custom: [SessionPreset]
    @Published private(set) var unlocked: Bool
    /// The theme the user picked. It only shows while it is available; see `theme`.
    @Published private(set) var selectedTheme: Theme

    let engine: SessionEngine
    let store: Store
    private let connectivity: PeerConnectivity

    init() {
        let connectivity = PeerConnectivity()
        let store = Store()
        self.connectivity = connectivity
        self.store = store
        templates = Catalog.templates(applying: SessionStore.loadTemplates())
        custom = SessionStore.loadPresets() ?? []
        unlocked = store.unlocked
        selectedTheme = SessionStore.loadTheme()
        engine = SessionEngine(platform: .init(
            delivers: { DeliveryPlan.resolve(target: $0.target, watchAvailable: connectivity.peerAvailable).phone },
            peerShouldKnow: { DeliveryPlan.resolve(target: $0.target, watchAvailable: connectivity.peerAvailable).watch },
            play: { PhoneAlert.play() },
            send: { connectivity.send($0) }
        ))

        store.onUnlockedChange = { [weak self] unlocked in
            self?.unlocked = unlocked
            self?.syncToWatch()
            self?.matchAppIcon()
        }
        connectivity.onMessage = { [weak self] message in self?.engine.handle(message) }
        connectivity.onActivated = { [weak self] in
            self?.syncToWatch()
            self?.engine.reconcile()
        }
        connectivity.activate()
    }

    /// A paired Apple Watch with Nudgy installed.
    var watchAvailable: Bool { connectivity.peerAvailable }

    // MARK: Timers

    /// Built-in timers the user may start.
    var availableTemplates: [SessionPreset] {
        templates.filter { Catalog.isAvailable($0, unlocked: unlocked) }
    }

    /// Built-in timers shown under "Upgrade to Access".
    var lockedTemplates: [SessionPreset] {
        Catalog.locked(templates: templates, unlocked: unlocked)
    }

    func start(_ preset: SessionPreset) {
        guard Catalog.isAvailable(preset, unlocked: unlocked) else { return }
        engine.start(preset)
    }

    func setRepeats(_ repeats: Bool, for preset: SessionPreset) {
        if let i = templates.firstIndex(where: { $0.id == preset.id }) {
            templates[i].repeats = repeats
        } else if let i = custom.firstIndex(where: { $0.id == preset.id }) {
            custom[i].repeats = repeats
        }
        persist()
    }

    func save(_ preset: SessionPreset) {
        guard unlocked else { return }
        let p = preset.normalized()
        if let i = custom.firstIndex(where: { $0.id == p.id }) {
            custom[i] = p
        } else {
            custom.append(p)
        }
        persist()
    }

    func delete(at offsets: IndexSet) {
        custom.remove(atOffsets: offsets)
        persist()
    }

    // MARK: Themes

    /// The theme shown: the user's pick, or Basic while that pick needs the unlock.
    var theme: Theme { Theme.effective(selected: selectedTheme, unlocked: unlocked) }

    /// Switches theme and the matching app icon. Locked themes are ignored.
    func select(_ theme: Theme) {
        guard theme.isAvailable(unlocked: unlocked) else { return }
        selectedTheme = theme
        SessionStore.saveTheme(theme)
        syncToWatch()
        matchAppIcon()
    }

    /// Sets the home-screen icon to the one for the theme shown. iOS tells the user itself
    /// when the icon changes.
    private func matchAppIcon() {
        let app = UIApplication.shared
        let wanted = theme.alternateIconName
        guard app.supportsAlternateIcons, app.alternateIconName != wanted else { return }
        app.setAlternateIconName(wanted) { _ in }
    }

    /// Lets the user hear and feel a nudge on the iPhone.
    func previewNudge() {
        PhoneAlert.play()
    }

    // MARK: Private

    private func persist() {
        SessionStore.saveTemplates(templates)
        SessionStore.savePresets(custom)
        syncToWatch()
    }

    /// The Watch only ever receives timers the user may start and the theme to show,
    /// so it needs no purchase logic.
    private func syncToWatch() {
        connectivity.pushAppState(
            presets: Catalog.available(templates: templates, custom: custom, unlocked: unlocked),
            theme: theme
        )
    }
}
