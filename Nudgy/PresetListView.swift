import SwiftUI
import NudgyKit

struct PresetListView: View {
    @EnvironmentObject private var model: AppModel
    @State private var editing: SessionPreset?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(model.presets) { preset in
                        Button {
                            model.start(preset)
                        } label: {
                            PresetRow(preset: preset)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .leading) {
                            Button("Edit") { editing = preset }.tint(.blue)
                        }
                    }
                    .onDelete { model.delete(at: $0) }
                } footer: {
                    Text("Tap a session to start it. Swipe right to edit, left to delete.")
                }
            }
            .navigationTitle("Nudgy")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        editing = SessionPreset(name: "", durationMinutes: 45, nudgeMinutesBeforeEnd: [10, 5, 0])
                    } label: {
                        Label("New session", systemImage: "plus")
                    }
                }
            }
            .sheet(item: $editing) { preset in
                PresetEditorView(preset: preset)
            }
        }
    }
}

struct PresetRow: View {
    let preset: SessionPreset

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(preset.name).font(.headline)
                Text(summary).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "play.circle.fill")
                .font(.title2)
                .foregroundStyle(.tint)
        }
        .contentShape(Rectangle())
    }

    private var summary: String {
        let nudges = preset.nudgeMinutesBeforeEnd.map { $0 == 0 ? "end" : "\($0)" }.joined(separator: " · ")
        let nudgeText = nudges.isEmpty ? "no nudges" : "nudges at \(nudges)"
        return "\(preset.durationMinutes) min · \(nudgeText) · \(preset.target.label)"
    }
}
