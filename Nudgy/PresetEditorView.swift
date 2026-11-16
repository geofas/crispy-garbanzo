import SwiftUI
import NudgyKit

/// Editor for a timer the user created.
struct PresetEditorView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State var preset: SessionPreset

    /// Minutes before the end that can be switched on.
    private static let nudgeChoices = [30, 20, 15, 10, 5, 3, 2, 1, 0]

    private var availableChoices: [Int] {
        Self.nudgeChoices.filter { $0 <= preset.durationMinutes }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Weekly team meeting", text: $preset.name)
                }

                Section {
                    Stepper(
                        "\(preset.durationMinutes) min",
                        value: $preset.durationMinutes,
                        in: SessionPreset.minDurationMinutes...SessionPreset.maxDurationMinutes,
                        step: 5
                    )
                    Toggle("Repeat until I end it", isOn: $preset.repeats)
                } header: {
                    Text("Length")
                }

                Section {
                    ForEach(availableChoices, id: \.self) { minutes in
                        Toggle(minutes == 0 ? "At the end" : "\(minutes) min before the end", isOn: binding(for: minutes))
                    }
                } header: {
                    Text("Nudges")
                } footer: {
                    Text("Up to \(SessionPreset.maxNudges) nudges. Each nudge is one flash, one ding and one vibration.")
                }

                Section {
                    Picker("Nudge on", selection: $preset.target) {
                        ForEach(NudgeTarget.allCases, id: \.self) { Text($0.label).tag($0) }
                    }
                } footer: {
                    if preset.target != .phone && !model.watchAvailable {
                        Text("No Apple Watch with Nudgy found. Nudges will go to the iPhone.")
                    }
                }

                Section {
                    Button("Try a nudge on this iPhone") { model.previewNudge() }
                }
            }
            .navigationTitle("Timer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        model.save(preset)
                        dismiss()
                    }
                }
            }
            .onChange(of: preset.durationMinutes) { _, duration in
                preset.nudgeSecondsBeforeEnd.removeAll { $0 > duration * 60 }
            }
        }
    }

    private func binding(for minutes: Int) -> Binding<Bool> {
        let seconds = minutes * 60
        return Binding(
            get: { preset.nudgeSecondsBeforeEnd.contains(seconds) },
            set: { on in
                if on {
                    guard preset.nudgeSecondsBeforeEnd.count < SessionPreset.maxNudges else { return }
                    preset.nudgeSecondsBeforeEnd.append(seconds)
                } else {
                    preset.nudgeSecondsBeforeEnd.removeAll { $0 == seconds }
                }
            }
        )
    }
}
