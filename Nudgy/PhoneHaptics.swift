import UIKit

/// In-app haptics on iPhone (only while Nudgy is in the foreground; silent, no sound).
enum PhoneHaptics {
    static func play(taps: Int) {
        Task { @MainActor in
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            for i in 0..<max(1, taps) {
                generator.impactOccurred(intensity: 1.0)
                if i < taps - 1 {
                    try? await Task.sleep(nanoseconds: 450_000_000)
                }
            }
        }
    }
}
