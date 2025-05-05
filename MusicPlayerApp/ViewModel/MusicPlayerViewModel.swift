import Foundation
import Combine
import SwiftUI   // For @MainActor
import AVFoundation

// MARK: - MusicPlayerViewModel
/// ViewModel for the music player. Connects the UI to the AudioService.
@MainActor
class MusicPlayerViewModel: ObservableObject {
    
    // MARK: - Dependencies
    let audioService: AudioService
    
    // MARK: - Published properties for UI binding

    @Published private(set) var currentTrack: TrackModel?     // The currently playing track
    @Published private(set) var isPlaying = false             // Is audio currently playing?
    @Published private(set) var progress: Double = 0          // Playback progress (0.0 to 1.0)
    @Published private(set) var duration: TimeInterval = 0    // Total duration (seconds)
    @Published private(set) var currentTime: TimeInterval = 0 // Current playback time (seconds)
    @Published private(set) var error: Error?                 // Any playback error
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()  // For Combine subscriptions
    private var timer: Timer?
    
    // MARK: - Initialize with an AudioService (default provided).

    init(audioService: AudioService) {
        self.audioService = audioService
        self.audioService.audioServiceDelegate = self
        setupBindings()
        startPlaybackMonitoring()
    }
    
    // MARK: - Public Methods
    /// Clear any error.
    func clearError() {
        error = nil
        audioService.error = nil
    }
    
    func resetPlayer() {
        audioService.pause() // Pause the audio
        isPlaying = false    // Update the play/pause button state
        currentTime = 0      // Reset the seekbar to the beginning
    }
    
    private func startPlaybackMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.currentTime = self.audioService.getCurrentTime()
                if self.currentTime >= self.duration && self.duration > 0 {
                    self.resetPlayer()
                }
            }
        }
    }
    
    /// Play a selected track.
     /// - Parameter track: The track to play.
    func play(track: TrackModel) async {
        do {
            try await audioService.play(track: track)
            duration = audioService.getDuration()
            isPlaying = true
            currentTrack = track
        } catch {
            print("Error playing track: \(error)")
            self.error = error
        }
    }
 
    /// Toggle play/pause.
    func togglePlayPause() {
        print("is Playing",isPlaying)
        if isPlaying {
            audioService.pause()
        } else {
            audioService.resume()
        }
    }
    
    /// Seek to a position (0.0 to 1.0).
       /// - Parameter progress: The progress value to seek to.
    func seek(to progress: Double) {
        let time = duration * progress
        audioService.seek(to: time)
    }
    
    // MARK: - Private Methods
    /// Bind AudioService properties to ViewModel properties.
    private func setupBindings() {
        audioService.$isPlaying
            .assign(to: &$isPlaying)
        
        audioService.$currentTime
            .assign(to: &$currentTime)
        
        audioService.$duration
            .assign(to: &$duration)
        
        audioService.$error
            .assign(to: &$error)
        
        $currentTime
            .combineLatest($duration)
            .map { currentTime , duration in
                guard duration > 0 else { return 0 }
                return currentTime / duration
            }.assign(to: &$progress)
        
        
    }
} 
extension MusicPlayerViewModel : AudioServiceProtocol {
    
    func pause() {
        
    }
    
    func resume() {
        
    }
    
    func stop() {
        resetPlayer()
    }
    
    func setVolume(_ volume: Float) {
        
    }
    
}
