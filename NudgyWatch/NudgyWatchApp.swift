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
                .environmentObject(model.engine)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { model.didBecomeActive() }
        }
    }
}

struct WatchRootView: View {
    @EnvironmentObject private var engine: SessionEngine

    var body: some View {
        if let session = engine.active {
            WatchRunningView(session: session)
        } else {
            WatchPresetListView()
        }
    }
}

struct WatchPresetListView: View {
    @EnvironmentObject private var model: WatchModel
    @EnvironmentObject private var engine: SessionEngine

    var body: some View {
        NavigationStack {
            List(model.presets) { preset in
                Button {
                    engine.start(preset)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(preset.name).font(.headline)
                        Text(preset.repeats ? "\(preset.durationMinutes) min · repeats" : "\(preset.durationMinutes) min")
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
    @EnvironmentObject private var engine: SessionEngine
    let session: ActiveSession
    @State private var confirmStop = false

    var body: some View {
        VStack(spacing: 6) {
            Label(session.presetName, systemImage: session.repeats ? "repeat" : "timer")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            // Only this block redraws each second.
            TimelineView(.periodic(from: session.startDate, by: 1)) { context in
                let now = context.date
                VStack(spacing: 6) {
                    Text(CountdownFormatter.string(session.remaining(at: now)))
                        .font(.system(size: 40, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .foregroundStyle(session.isFinished(at: now) ? .red : .primary)

                    if let next = session.nextNudge(after: now) {
                        Text("Next: \(next.message)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        if engine.delivering && !model.patternsActive {
                            Text("Standard taps only")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }

            Button("End", role: .destructive) { confirmStop = true }
                .padding(.top, 4)
        }
        .confirmationDialog("End this session?", isPresented: $confirmStop, titleVisibility: .visible) {
            Button("End session", role: .destructive) { engine.stop() }
            Button("Keep running", role: .cancel) {}
        }
    }
}
