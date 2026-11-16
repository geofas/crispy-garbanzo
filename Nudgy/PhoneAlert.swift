import AudioToolbox
import Foundation

/// One nudge on iPhone: a ding and a vibration, while Nudgy is in the foreground.
/// The ding follows the ring/silent setting: in Silent Mode the iPhone only vibrates.
enum PhoneAlert {
    private static let ding: SystemSoundID = {
        var id: SystemSoundID = 0
        if let url = Bundle.main.url(forResource: "ding", withExtension: "wav") {
            AudioServicesCreateSystemSoundID(url as CFURL, &id)
        }
        return id
    }()

    static func play() {
        // Plays the sound and vibrates (the vibration also comes in Silent Mode).
        AudioServicesPlayAlertSound(ding == 0 ? kSystemSoundID_Vibrate : ding)
    }
}
