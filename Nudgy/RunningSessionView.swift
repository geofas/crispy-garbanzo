import SwiftUI
import NudgyKit

struct RunningSessionView: View {
    @EnvironmentObject private var model: AppModel
    @State private var confirmStop = false

    var body: some View {
        if let session = model.active {
            VStack(spacing: 24) {
                Text(session.presetName)
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text(CountdownFormatter.string(session.remaining(at: model.now)))
                    .font(.system(size: 76, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .foregroundStyle(session.isFinished(at: model.now) ? .red : .primary)

                if let next = session.nextNudge(after: model.now) {
                    Text("Next nudge: \(next.message) · \(next.taps) tap\(next.taps == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text(session.isFinished(at: model.now) ? "Over time" : "No more nudges")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text("Nudging on: \(DeliveryPlanLabel.text(for: session.target, watchAvailable: model.watchAvailable))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

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
                Button("End session", role: .destructive) { model.stop() }
                Button("Keep running", role: .cancel) {}
            }
        }
    }
}

enum DeliveryPlanLabel {
    static func text(for target: NudgeTarget, watchAvailable: Bool) -> String {
        let plan = DeliveryPlan.resolve(target: target, watchAvailable: watchAvailable)
        switch (plan.phone, plan.watch) {
        case (true, true): return "Watch + iPhone"
        case (false, true): return "Apple Watch"
        default: return "iPhone"
        }
    }
}
