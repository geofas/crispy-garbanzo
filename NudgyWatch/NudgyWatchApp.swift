import SwiftUI
import NudgyKit

@main
struct NudgyWatchApp: App {
    @StateObject private var model = WatchModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            WatchRootView()
                .environmentObject(model)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { model.didBecomeActive() }
        }
    }
}

struct WatchRootView: View {
    @EnvironmentObject private var model: WatchModel

    var body: some View {
        if let session = model.active {
            WatchRunningView(session: session)
        } else {
            WatchPresetListView()
        }
    }
}

struct WatchPresetListView: View {
    @EnvironmentObject private var model: WatchModel

    var body: some View {
        NavigationStack {
            List(model.presets) { preset in
                Button {
                    model.start(preset)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(preset.name).font(.headline)
                        Text("\(preset.durationMinutes) min")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Nudgy")
        }
    }
}

struct WatchRunningView: View {
    @EnvironmentObject private var model: WatchModel
    let session: ActiveSession
    @State private var confirmStop = false

    var body: some View {
        VStack(spacing: 6) {
            Text(session.presetName)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Text(CountdownFormatter.string(session.remaining(at: model.now)))
                .font(.system(size: 40, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundStyle(session.isFinished(at: model.now) ? .red : .primary)

            if let next = session.nextNudge(after: model.now) {
                Text("Next: \(next.message)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if !model.patternsActive && !session.isFinished(at: model.now) {
                Text("Standard taps only")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }

            Button("End", role: .destructive) { confirmStop = true }
                .padding(.top, 4)
        }
        .confirmationDialog("End this session?", isPresented: $confirmStop, titleVisibility: .visible) {
            Button("End session", role: .destructive) { model.stop() }
            Button("Keep running", role: .cancel) {}
        }
    }
}
