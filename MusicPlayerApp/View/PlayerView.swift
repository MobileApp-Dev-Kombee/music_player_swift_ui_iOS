//
//  PlayerView.swift
//  MusicPlayer
//
//  Created by iMac on 30/04/25.
//

import SwiftUI

// MARK: - PlayerView
/// Main UI for the music player demo.
struct PlayerView: View {
    @ObservedObject  var viewModel : MusicPlayerViewModel // ViewModel for state and actions
    @State private var volume: Float = 1.0  // Volume slider value
    
    // Demo tracks: online and offline
    let onlineTracks = [
        TrackModel(title: "Online Track 1", artist: "Artist 1", url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3", isLocal: false),
        TrackModel(title: "Online Track 2", artist: "Artist 2", url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3", isLocal: false)
    ]
    
    let offlineTracks = [
        TrackModel(title: "Offline Track 1", artist: "Artist 3", url: "1", isLocal: true),
        TrackModel(title: "Offline Track 2", artist: "Artist 4", url: "2", isLocal: true),
        TrackModel(title: "Offline Track 3", artist: "Artist 5", url: "3", isLocal: true),
        TrackModel(title: "Offline Track 4", artist: "Artist 6", url: "4", isLocal: true),
        TrackModel(title: "Offline Track 5", artist: "Artist 7", url: "5", isLocal: true)
    ]
    
    var body: some View {
        NavigationView { // Navigation container
            VStack(spacing: 20) { // Vertical stack with spacing
                // List of tracks, separated by online/offline
                List {
                    Section(header: Text(AppConstants.Strings.onlineTrack)) { // Online section
                        ForEach(onlineTracks) { track in
                            TrackRowView(track: track) {
                                Task {
                                    await viewModel.play(track: track) // Play selected track
                                }
                            }
                        }
                    }
                    Section(header: Text(AppConstants.Strings.offlineTrack)) { // Offline section
                        ForEach(offlineTracks) { track in
                            TrackRowView(track: track) {
                                Task {
                                    await viewModel.play(track: track) // Play selected track
                                }
                            }
                        }
                    }
                }
                
                // Playback progress and controls
                VStack {
                    if viewModel.duration > 0 { // Show controls if a track is loaded
                        VStack {
                            if let curentTrack = viewModel.currentTrack {
                                Text(curentTrack.title)
                                    .bold()
                                    .foregroundColor(.blue)
                                Text(curentTrack.artist)
                                    .foregroundColor(.gray)
                            }
                            ProgressView(value: min(max(viewModel.currentTime, 0), viewModel.duration), total: viewModel.duration)
                            HStack {
                                Text(formatTime(viewModel.currentTime))
                                Spacer()
                                Text(formatTime(viewModel.duration))
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding()
                        HStack(spacing: 40) {
                            Button(action: {
                                viewModel.togglePlayPause()  // Play/Pause button
                            }) {
                                Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                    .font(.system(size: 44))
                            }
                            HStack {
                                Image(systemName: "speaker.fill")
                                Slider(value: $volume, in: 0...1) { _ in
                                    viewModel.audioService.setVolume(volume)    // Volume(Audio) slider
                                }
                                Image(systemName: "speaker.wave.3.fill")
                            }
                        }
                        .padding()
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius:5,x:0,y:2)
                .padding()
            }
            .navigationTitle(AppConstants.Strings.appTitle)
            .alert(AppConstants.Strings.error, isPresented: .constant(viewModel.error != nil)) {
                Button(AppConstants.Strings.ok) {
                    viewModel.clearError()
                }
            } message: {
                if let error = viewModel.error {
                    Text(error.localizedDescription)
                }
            }
        }
    }
    
    /// Format seconds as mm:ss.
       /// - Parameter time: TimeInterval to format.
       /// - Returns: String in mm:ss format.
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - TrackRowView
/// Row for a single track in the list.
struct TrackRowView: View {
    let track: TrackModel  // Track to display
    let action: () -> Void // Action when tapped
    
    var body: some View {
        Button(action: action) { // Button for track selection
            HStack {
                VStack(alignment: .leading) {
                    Text(track.title)
                        .font(.headline)
                    Text(track.artist)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
