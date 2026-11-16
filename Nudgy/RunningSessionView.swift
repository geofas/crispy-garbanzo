import SwiftUI
import NudgyKit

struct RunningSessionView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var engine: SessionEngine
    let session: ActiveSession
    @State private var confirmStop = false

    var body: some View {
        VStack(spacing: 24) {
            Text(session.presetName)
                .font(.headline)
                .foregroundStyle(.secondary)

            // Only this block redraws each second; nothing else in the app does.
            TimelineView(.periodic(from: session.startDate, by: 1)) { context in
                let now = context.date
                VStack(spacing: 24) {
                    Text(CountdownFormatter.string(session.remaining(at: now)))
                        .font(.system(size: 76, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .foregroundStyle(session.isFinished(at: now) ? .red : .primary)

                    Text(status(at: now))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("Nudging on: \(DeliveryPlan.resolve(target: session.target, watchAvailable: model.watchAvailable).label)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Button(role: .destructive) {
                confirmStop = true
            } label: {
                Text("End session").frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .padding(.top, 24)
        }
        .padding(32)
        .confirmationDialog("End this session?", isPresented: $confirmStop, titleVisibility: .visible) {
            Button("End session", role: .destructive) { engine.stop() }
            Button("Keep running", role: .cancel) {}
        }
    }

    private func status(at now: Date) -> String {
        if let next = session.nextNudge(after: now) {
            return "Next nudge: \(next.message) · \(next.taps) tap\(next.taps == 1 ? "" : "s")"
        }
        return session.isFinished(at: now) ? "Over time" : "No more nudges"
    }
}
