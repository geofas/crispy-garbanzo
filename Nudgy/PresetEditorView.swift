import SwiftUI
import NudgyKit

struct PresetEditorView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State var preset: SessionPreset

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

                Section("Length") {
                    Stepper(
                        "\(preset.durationMinutes) min",
                        value: $preset.durationMinutes,
                        in: SessionPreset.minDurationMinutes...SessionPreset.maxDurationMinutes,
                        step: 5
                    )
                }

                Section {
                    ForEach(availableChoices, id: \.self) { minutes in
                        Toggle(minutes == 0 ? "At the end" : "\(minutes) min before the end", isOn: binding(for: minutes))
                    }
                } header: {
                    Text("Nudges")
                } footer: {
                    Text("Up to \(SessionPreset.maxNudges) nudges. Last warning = 2 taps, end = 3 taps, earlier = 1 tap.")
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

                Section("Try the patterns on this iPhone") {
                    HStack {
                        ForEach(1...3, id: \.self) { taps in
                            Button("\(taps) tap\(taps == 1 ? "" : "s")") { model.preview(taps: taps) }
                                .buttonStyle(.bordered)
                        }
                    }
                }
            }
            .navigationTitle("Session")
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
                preset.nudgeMinutesBeforeEnd.removeAll { $0 > duration }
            }
        }
    }

    private func binding(for minutes: Int) -> Binding<Bool> {
        Binding(
            get: { preset.nudgeMinutesBeforeEnd.contains(minutes) },
            set: { on in
                if on {
                    guard preset.nudgeMinutesBeforeEnd.count < SessionPreset.maxNudges else { return }
                    preset.nudgeMinutesBeforeEnd.append(minutes)
                } else {
                    preset.nudgeMinutesBeforeEnd.removeAll { $0 == minutes }
                }
            }
        )
    }
}
