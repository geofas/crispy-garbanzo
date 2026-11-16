import SwiftUI
import NudgyKit

struct PresetListView: View {
    @EnvironmentObject private var model: AppModel
    @State private var editing: SessionPreset?
    @State private var showingUpgrade = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(model.availableTemplates) { preset in
                        TimerRow(preset: preset)
                    }
                } footer: {
                    Text("Tap a timer to start it. The loop button makes it restart by itself until you end it.")
                }

                if model.unlocked {
                    Section {
                        ForEach(model.custom) { preset in
                            TimerRow(preset: preset)
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
                        }
                        LockedRow(title: "Your own timers", subtitle: "Any length, your own nudges") {
                            showingUpgrade = true
                        }
                    } header: {
                        Text("Upgrade to Access")
                    } footer: {
                        Button("Upgrade") { showingUpgrade = true }
                            .buttonStyle(.borderedProminent)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("Nudgy")
            .sheet(item: $editing) { preset in
                PresetEditorView(preset: preset)
            }
            .sheet(isPresented: $showingUpgrade) {
                UpgradeView()
            }
        }
    }
}

/// A timer the user may start.
struct TimerRow: View {
    @EnvironmentObject private var model: AppModel
    let preset: SessionPreset

    var body: some View {
        HStack(spacing: 12) {
            Button {
                model.start(preset)
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(preset.name).font(.headline)
                        Text(Self.summary(for: preset)).font(.subheadline).foregroundStyle(.secondary)
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
                    .foregroundStyle(preset.repeats ? Color.white : Color.secondary)
                    .padding(8)
                    .background(preset.repeats ? Color.accentColor : Color.secondary.opacity(0.15), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Repeat")
            .accessibilityValue(preset.repeats ? "On" : "Off")
        }
    }

    static func summary(for preset: SessionPreset) -> String {
        var parts = ["\(preset.durationMinutes) min"]
        parts.append(preset.nudgeSummary.map { "nudges at \($0)" } ?? "no nudges")
        if preset.repeats { parts.append("repeats") }
        return parts.joined(separator: " · ")
    }
}

/// A timer shown under "Upgrade to Access": visible, dimmed, and not startable.
struct LockedRow: View {
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "lock.fill")
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .opacity(0.8)
        .accessibilityHint("Locked. Opens the upgrade screen.")
    }
}
