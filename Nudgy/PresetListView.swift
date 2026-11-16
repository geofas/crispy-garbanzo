import SwiftUI
import NudgyKit

struct PresetListView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var store: Store
    @Environment(\.themeStyle) private var style
    @State private var editing: SessionPreset?
    @State private var showingUpgrade = false
    @State private var showingThemes = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(model.availableTemplates) { preset in
                        TimerRow(preset: preset)
                            .themedRow(style)
                    }
                } footer: {
                    Text("Tap a timer to start it. The loop button makes it restart by itself until you end it.")
                }

                if model.unlocked {
                    Section {
                        ForEach(model.custom) { preset in
                            TimerRow(preset: preset)
                                .themedRow(style)
                                .swipeActions(edge: .leading) {
                                    Button("Edit") { editing = preset }.tint(.blue)
                                }
                        }
                        .onDelete { model.delete(at: $0) }

                        Button {
                            editing = SessionPreset(name: "", durationMinutes: 45, nudgeMinutesBeforeEnd: [10, 5, 0])
                        } label: {
                            Label("New timer", systemImage: "plus")
                        }
                        .themedRow(style)
                    } header: {
                        Text("Your timers")
                    } footer: {
                        if !model.custom.isEmpty {
                            Text("Swipe right to edit, left to delete.")
                        }
                    }
                } else {
                    Section {
                        ForEach(model.lockedTemplates) { preset in
                            LockedRow(title: preset.name, subtitle: TimerRow.summary(for: preset)) {
                                showingUpgrade = true
                            }
                            .themedRow(style)
                        }
                        LockedRow(title: "Your own timers", subtitle: "Any length, nudges wherever you want them") {
                            showingUpgrade = true
                        }
                        .themedRow(style)
                        LockedRow(title: "Themes", subtitle: "Quiet Signal and Friendly Tap") {
                            showingUpgrade = true
                        }
                        .themedRow(style)
                    } header: {
                        Text("Unlock with the one-time purchase")
                    } footer: {
                        VStack(spacing: 6) {
                            Button { showingUpgrade = true } label: {
                                Text(unlockTitle).frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .foregroundStyle(style.onAccent)
                            .controlSize(.large)
                            Text("Pay once. No subscription.")
                                .font(style.text(.footnote))
                                .foregroundStyle(style.secondaryText)
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .themedListBackground(style)
            .navigationTitle("Nudgy")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingThemes = true } label: {
                        Image(systemName: "paintpalette")
                    }
                    .accessibilityLabel("Theme")
                }
            }
            .sheet(item: $editing) { preset in
                PresetEditorView(preset: preset).themed(model.theme)
            }
            .sheet(isPresented: $showingUpgrade) {
                UpgradeView().themed(model.theme)
            }
            .sheet(isPresented: $showingThemes) {
                ThemePickerView().themed(model.theme)
            }
        }
    }

    /// "Unlock all · €4.99" once the App Store has returned the price; "Unlock all" before that.
    private var unlockTitle: String {
        if let price = store.product?.displayPrice { return "Unlock all · \(price)" }
        return "Unlock all"
    }
}

/// A timer the user may start.
struct TimerRow: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.themeStyle) private var style
    let preset: SessionPreset

    var body: some View {
        HStack(spacing: 12) {
            Button {
                model.start(preset)
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(preset.name).font(style.text(.headline, weight: .semibold))
                        Text(Self.summary(for: preset)).font(style.text(.subheadline)).foregroundStyle(style.secondaryText)
                    }
                    Spacer()
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.tint)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                model.setRepeats(!preset.repeats, for: preset)
            } label: {
                Image(systemName: "repeat")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(preset.repeats ? style.onAccent : style.secondaryText)
                    .padding(8)
                    .background(preset.repeats ? style.accent : style.secondaryText.opacity(0.15), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Repeat")
            .accessibilityValue(preset.repeats ? "On" : "Off")
        }
    }

    static func summary(for preset: SessionPreset) -> String {
        var parts = [preset.durationLabel]
        parts.append(preset.nudgeSummary.map { "nudges at \($0)" } ?? "no nudges")
        if preset.repeats { parts.append("repeats") }
        return parts.joined(separator: " · ")
    }
}

/// A timer shown under "Upgrade to Access": visible, dimmed, and not startable.
struct LockedRow: View {
    @Environment(\.themeStyle) private var style
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(style.text(.headline, weight: .semibold))
                    Text(subtitle).font(style.text(.subheadline)).foregroundStyle(style.secondaryText)
                }
                Spacer()
                Image(systemName: "lock.fill")
                    .foregroundStyle(style.secondaryText)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(0.8)
        .accessibilityHint("Locked. Opens the upgrade screen.")
    }
}
