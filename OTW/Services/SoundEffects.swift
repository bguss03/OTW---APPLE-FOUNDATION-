import AVFoundation

/// Short UI sounds. Uses the `.ambient` session so the silent switch is respected and the
/// user's music keeps playing.
final class SoundEffects {
    static let shared = SoundEffects()

    private var savePlayer: AVAudioPlayer?

    /// Loads and primes `save_sound.caf`; call when New Plan opens so playback has no delay.
    func prepare() {
        guard savePlayer == nil, let url = Bundle.main.url(forResource: "save_sound", withExtension: "caf") else { return }
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default)
        try? session.setActive(true)
        savePlayer = try? AVAudioPlayer(contentsOf: url)
        savePlayer?.prepareToPlay()
    }

    func playSave() {
        prepare()
        savePlayer?.currentTime = 0
        let started = savePlayer?.play() ?? false
        #if DEBUG
        print("[OTW] save sound started: \(started), session: \(AVAudioSession.sharedInstance().category.rawValue)")
        #endif
    }
}
