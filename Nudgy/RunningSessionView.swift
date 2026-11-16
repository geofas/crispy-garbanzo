import SwiftUI
import NudgyKit

struct RunningSessionView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var engine: SessionEngine
    @Environment(\.themeStyle) private var style
    let session: ActiveSession
    @State private var confirmStop = false

    var body: some View {
        VStack(spacing: 20) {
            Text(session.presetName)
                .font(style.text(.headline, weight: .semibold))
                .foregroundStyle(style.secondaryText)

            // Only this block redraws each second; nothing else in the app does.
            TimelineView(.periodic(from: session.startDate, by: 1)) { context in
                let now = context.date
                VStack(spacing: 20) {
                    if session.repeats {
                        Label("Round \(session.cycleIndex(at: now) + 1) · repeats until you end it", systemImage: "repeat")
                            .font(style.text(.subheadline))
                            .foregroundStyle(style.secondaryText)
                    }

                    Text(CountdownFormatter.string(session.remaining(at: now)))
                        .font(style.display(76))
                        .monospacedDigit()
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .foregroundStyle(session.isFinished(at: now) ? style.destructive : style.primaryText)

                    Text(status(at: now))
                        .font(style.text(.title3, weight: .semibold))

                    RoundStepsList(steps: session.roundSteps(at: now))
                }
            }

            Text("Nudging on: \(DeliveryPlan.resolve(target: session.target, watchAvailable: model.watchAvailable).label)")
                .font(style.text(.footnote))
                .foregroundStyle(style.secondaryText)

            Spacer(minLength: 0)

            Button(role: .destructive) {
                confirmStop = true
            } label: {
                Text("End session").frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(style.destructive)
            .controlSize(.large)
            // Attached to the button so the confirmation appears from it.
            .confirmationDialog("End this session?", isPresented: $confirmStop, titleVisibility: .visible) {
                Button("End session", role: .destructive) { engine.stop() }
                Button("Keep running", role: .cancel) {}
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background((style.background ?? Color(.systemBackground)).ignoresSafeArea())
        .nudgeFlash(engine.nudgeFlash)
    }

    private func status(at now: Date) -> String {
        if let next = session.nextNudge(after: now) {
            return "Next nudge: \(next.message)"
        }
        return session.isFinished(at: now) ? "Over time" : "No more nudges"
    }
}

/// Every nudge of the current round in words: already played, next, and later.
private struct RoundStepsList: View {
    @Environment(\.themeStyle) private var style
    let steps: [RoundStep]

    var body: some View {
        if !steps.isEmpty {
            VStack(spacing: 0) {
                ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                    if index > 0 { Divider().padding(.leading, 16) }
                    HStack {
                        Text(step.label)
                            .font(style.text(.body, weight: step.state == .next ? .semibold : .regular))
                            .monospacedDigit()
                        Spacer()
                        Text(Self.stateLabel(step.state))
                            .font(style.text(.subheadline, weight: step.state == .next ? .semibold : .regular))
                    }
                    .foregroundStyle(step.state == .done ? style.secondaryText : style.primaryText)
                    .padding(.horizontal, 16)
                    .frame(minHeight: 44)
                    .background(step.state == .next ? style.highlight : Color.clear)
                    .accessibilityElement(children: .combine)
                }
            }
            .background(style.surface ?? Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private static func stateLabel(_ state: RoundStep.State) -> String {
        switch state {
        case .done: return "Done"
        case .next: return "Next"
        case .later: return ""
        }
    }
}
