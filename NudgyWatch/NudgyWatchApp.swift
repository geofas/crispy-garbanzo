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
    @EnvironmentObject private var model: WatchModel
    @EnvironmentObject private var engine: SessionEngine

    var body: some View {
        Group {
            if let session = engine.active {
                WatchRunningView(session: session)
            } else {
                WatchPresetListView()
            }
        }
        .themed(model.theme)
    }
}

struct WatchPresetListView: View {
    @EnvironmentObject private var model: WatchModel
    @EnvironmentObject private var engine: SessionEngine
    @Environment(\.themeStyle) private var style

    var body: some View {
        NavigationStack {
            List(model.presets) { preset in
                Button {
                    engine.start(preset)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(preset.name).font(style.text(.headline, weight: .semibold))
                            Text(preset.repeats ? "\(preset.durationLabel) · repeats" : preset.durationLabel)
                                .font(style.text(.caption))
                                .foregroundStyle(style.secondaryText)
                        }
                        Spacer()
                        Image(systemName: "play.fill")
                            .font(.caption)
                            .foregroundStyle(style.accent)
                            .accessibilityHidden(true)
                    }
                }
                .themedRow(style)
            }
            .navigationTitle("Nudgy")
        }
    }
}

struct WatchRunningView: View {
    @EnvironmentObject private var model: WatchModel
    @EnvironmentObject private var engine: SessionEngine
    @Environment(\.themeStyle) private var style
    let session: ActiveSession
    @State private var confirmStop = false

    var body: some View {
        VStack(spacing: 6) {
            Label(session.presetName, systemImage: session.repeats ? "repeat" : "timer")
                .font(style.text(.caption))
                .foregroundStyle(style.secondaryText)
                .lineLimit(1)

            // Only this block redraws each second.
            TimelineView(.periodic(from: session.startDate, by: 1)) { context in
                let now = context.date
                VStack(spacing: 6) {
                    Text(CountdownFormatter.string(session.remaining(at: now)))
                        .font(style.display(40))
                        .monospacedDigit()
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .foregroundStyle(session.isFinished(at: now) ? style.destructive : style.primaryText)

                    let upcoming = session.upcomingNudges(after: now)
                    if let next = upcoming.first {
                        Text("Next: \(next.message)")
                            .font(style.text(.footnote, weight: .semibold))
                            .foregroundStyle(style.highlight)
                    }
                    if upcoming.count > 1 {
                        Text("Then: \(upcoming[1].message)")
                            .font(style.text(.caption2))
                            .foregroundStyle(style.secondaryText)
                    }
                }
            }

            Button("End", role: .destructive) { confirmStop = true }
                .confirmationDialog("End this session?", isPresented: $confirmStop, titleVisibility: .visible) {
                    Button("End session", role: .destructive) { engine.stop() }
                    Button("Keep running", role: .cancel) {}
                }
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .nudgeFlash(engine.nudgeFlash)
    }
}
