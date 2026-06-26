import AVFoundation
import Combine

public enum SoundEffect: String, CaseIterable {
    case step = "sfx_step"
    case pushBox = "sfx_push_box"
    case pushMirror = "sfx_push_mirror"
    case beamShimmer = "sfx_beam_shimmer"
    case sensorDestroyed = "sfx_sensor_destroyed"
    case capsuleCollected = "sfx_capsule"
    case doorUnlock = "sfx_door_unlock"
    case levelClear = "sfx_level_clear"
    case undo = "sfx_undo"
    case invalidMove = "sfx_invalid"
}

public enum MusicTrack: String {
    case menu = "menu_theme"
    case gameplay = "gameplay_theme"
}

/// Loads bundled placeholder SFX/music and plays them via `AVAudioPlayer`,
/// staying in sync with `SettingsStore`'s volume sliders.
public final class AudioManager {
    private let settings: SettingsStore
    private var cancellables: Set<AnyCancellable> = []

    /// A small pool per effect so rapid repeats (e.g. footsteps) don't cut each other off.
    private var sfxPlayers: [SoundEffect: [AVAudioPlayer]] = [:]
    private var musicPlayer: AVAudioPlayer?
    private var currentMusicTrack: MusicTrack?

    public init(settings: SettingsStore) {
        self.settings = settings
        preloadSFX()
        observeSettings()
    }

    private func resourceURL(_ name: String) -> URL? {
        Bundle.module.url(forResource: name, withExtension: "wav", subdirectory: "Resources/Audio")
    }

    private func preloadSFX() {
        for effect in SoundEffect.allCases {
            guard let url = resourceURL(effect.rawValue) else { continue }
            let pool = (0..<3).compactMap { _ in try? AVAudioPlayer(contentsOf: url) }
            pool.forEach { $0.prepareToPlay() }
            sfxPlayers[effect] = pool
        }
    }

    private func observeSettings() {
        settings.$sfxVolume
            .sink { [weak self] volume in
                self?.applySFXVolume(Float(volume))
            }
            .store(in: &cancellables)

        settings.$musicVolume
            .sink { [weak self] volume in
                self?.musicPlayer?.volume = Float(volume)
            }
            .store(in: &cancellables)
    }

    private func applySFXVolume(_ volume: Float) {
        for pool in sfxPlayers.values {
            pool.forEach { $0.volume = volume }
        }
    }

    public func play(_ effect: SoundEffect) {
        guard let pool = sfxPlayers[effect], !pool.isEmpty else { return }
        let player = pool.first(where: { !$0.isPlaying }) ?? pool[0]
        player.volume = Float(settings.sfxVolume)
        player.currentTime = 0
        player.play()
    }

    public func playMusic(_ track: MusicTrack) {
        guard currentMusicTrack != track else { return }
        guard let url = resourceURL(track.rawValue) else { return }

        let player = try? AVAudioPlayer(contentsOf: url)
        player?.numberOfLoops = -1
        player?.volume = Float(settings.musicVolume)
        player?.prepareToPlay()
        player?.play()

        musicPlayer = player
        currentMusicTrack = track
    }

    public func stopMusic() {
        musicPlayer?.stop()
        musicPlayer = nil
        currentMusicTrack = nil
    }
}
