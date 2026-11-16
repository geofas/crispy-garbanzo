import SwiftUI

/// Flashes the whole screen white when `trigger` changes (each nudge played on this device).
/// Only visible while the screen is on and Nudgy is in front.
struct NudgeFlash: ViewModifier {
    let trigger: Int
    @State private var opacity: Double = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                Color.white
                    .opacity(opacity)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
            .onChange(of: trigger) { _, _ in
                opacity = 1
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 200_000_000)
                    withAnimation(.easeOut(duration: 0.5)) { opacity = 0 }
                }
            }
    }
}

extension View {
    func nudgeFlash(_ trigger: Int) -> some View {
        modifier(NudgeFlash(trigger: trigger))
    }
}
