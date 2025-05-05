import AVFoundation
import Combine
import Foundation
import SwiftUI

// MARK: - AudioService
/// Handles all audio playback logic using AVPlayer.
/// Supports both online streaming and offline (bundled) files.
@MainActor
protocol AudioServiceProtocol: AnyObject {
    func play(track: TrackModel) async throws
    func pause()
    func resume()
    func stop()
    func seek(to time: TimeInterval)
    func setVolume(_ volume: Float)
    var currentTime: TimeInterval { get }
    var duration: TimeInterval { get }
    var isPlaying: Bool { get }
    var progress: Double { get }
    var playbackState: CurrentValueSubject<PlaybackState, Never> { get }
}

extension AudioServiceProtocol {

    func pause() {
        //default implementatation methos
    }

    func resume() {
        //default implementatation methos
    }

    func setVolume(_ volume: Float) {
        //default implementatation methos
    }

    var playbackState: CurrentValueSubject<PlaybackState, Never> {
        // Default value: a subject with an initial state of .stopped
        return CurrentValueSubject<PlaybackState, Never>(.stopped)
    }
}
enum PlaybackState {
    case playing
    case paused
    case stopped
    case error(Error)
}

enum AudioError: LocalizedError {
    case invalidTrack
    case fileNotFound
    case invalidURL
    case networkError
    case playbackError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidTrack:
            return "Invalid track"
        case .fileNotFound:
            return "Audio file not found"
        case .invalidURL:
            return "Invalid URL"
        case .networkError:
            return "Network connection failed"
        case .playbackError(let error):
            return "Playback error: \(error.localizedDescription)"
        }
    }
}

@MainActor
class AudioService: ObservableObject, AudioServiceProtocol {

    @Published private(set) var isPlaying = false
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    @Published var error: Error?

    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private var audioSession: AVAudioSession
    private var playerItemStatusObserver: NSKeyValueObservation?

    let playbackState = CurrentValueSubject<PlaybackState, Never>(.stopped)

    var audioServiceDelegate: AudioServiceProtocol?

    init() {
        audioSession = AVAudioSession.sharedInstance()
        setupAudioSession()
    }

    deinit {
        playerItemStatusObserver?.invalidate()
        playerItemStatusObserver = nil

        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
        }
        timeObserver = nil
        NotificationCenter.default.removeObserver(self)
        player = nil
        playerItem = nil
        // For operations that *must* happen on the MainActor, use Task.detached
        Task.detached(priority: .high) { @MainActor in
            try? AVAudioSession.sharedInstance().setActive(false)
            print(
                "AVAudioSession deactivated on MainActor during deinit (attempt)."
            )
            // Any other MainActor-specific cleanup that absolutely needs
            // to be on the main thread can go here.
        }

        print("Deinit called.")
    }

    /// Set active Audio Session
    private func setupAudioSession() {
        do {
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
        } catch {
            self.error = error
            print("Failed to set up audio session: \(error)")
        }
    }

    /// Play a track (online or offline).
    /// - Parameter track: The track to play.
    func play(track: TrackModel) async throws {
        stop()  // Stop any current playback

        // Determine the URL: local file or remote
        let url: URL?
        if track.isLocal {
            // For offline: look for the file in the app bundle
            url = Bundle.main.url(forResource: track.url, withExtension: "mp3")
        } else {
            // For online: use the provided URL string
            url = URL(string: track.url)
        }

        // If URL is invalid, set error and return
        guard let url = url else {
            error = NSError(
                domain: "AudioService", code: -1,
                userInfo: [NSLocalizedDescriptionKey: AudioError.invalidURL])
            return
        }

        // Create AVPlayer and start playback
        let playerItem = AVPlayerItem(url: url)  // Create player item
        player = AVPlayer(playerItem: playerItem)  // Create player
        setupTimeObserver()  // Start observing playback time
        player?.play()  // Start playback
        isPlaying = true  // Update state
        setupNotifications()
        playbackState.send(.playing)
    }

    /// Get current time of playing song
    func getCurrentTime() -> TimeInterval {
        let interval: TimeInterval = player?.currentTime().seconds ?? 0.0
        return interval
    }

    /// Get current duration of playing song
    func getDuration() -> TimeInterval {
        let interval: TimeInterval =
            player?.currentItem?.duration.seconds ?? 0.0
        return interval
    }

    /// Pause playback.
      func pause() {
          player?.pause() // Pause player
          isPlaying = false // Update state
      }

      /// Resume playback.
      func resume() {
          player?.play() // Resume player
          isPlaying = true // Update state
      }
    
    /// Stop playback and reset.
       func stop() {
           audioServiceDelegate?.stop()
           player?.pause() // Pause player
           player?.seek(to: .zero) // Seek to start
           isPlaying = false // Update state
           currentTime = 0 // Reset time
       }

    /// Seek to a specific time (in seconds).
        /// - Parameter time: The time to seek to.
        func seek(to time: TimeInterval) {
            let time = CMTime(seconds: time, preferredTimescale: 600) // Create CMTime
            player?.seek(to: time) // Seek player
        }

        /// Set playback volume (0.0 to 1.0).
        /// - Parameter volume: The volume level.
        func setVolume(_ volume: Float) {
            player?.volume = volume // Set player volume
        }

    /// Playback progress (0.0 to 1.0).
       var progress: Double {
           guard duration > 0 else { return 0 } // Avoid division by zero
           return currentTime / duration // Calculate progress
       }

    /// Set up a periodic observer to update currentTime and duration.
    private func setupTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(
            forInterval: interval, queue: .main
        ) { [weak self] time in
            DispatchQueue.main.async {
                self?.currentTime = time.seconds // update currenttime
                if let duration = self?.player?.currentItem?.duration.seconds {
                    self?.duration = duration   // update duration
                }
            }
        }
    }

    ///Setup notification observar for player End and interrupt
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidReachEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil)
    }

    ///PlayerEnd  audio sesssion manage
    @objc private func playerItemDidReachEnd() {
        stop()
    }

    ///interruptionNotification audio sesssion manage
    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey]
                as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else {
            return
        }

        switch type {
        case .began:
            pause()
        case .ended:
            guard
                let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey]
                    as? UInt
            else { return }
            let options = AVAudioSession.InterruptionOptions(
                rawValue: optionsValue)
            if options.contains(.shouldResume) {
                resume()
            }
        @unknown default:
            break
        }
    }

}
