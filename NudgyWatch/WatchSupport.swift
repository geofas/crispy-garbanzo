import Foundation
import WatchKit
import NudgyKit

/// One nudge on the wrist: the strongest standard haptic, which also plays a sound
/// unless the Watch is in Silent Mode.
enum WatchHaptics {
    static func play() {
        WKInterfaceDevice.current().play(.notification)
    }
}
