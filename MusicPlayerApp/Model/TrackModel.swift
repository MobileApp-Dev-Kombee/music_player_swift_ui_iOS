//
//  TrackModel.swift
//  MusicPlayer
//
//  Created by iMac on 30/04/25.
//

import Foundation

/// Data model representing a music track (either online or offline).
struct TrackModel: Identifiable {
    let id: UUID                // Unique identifier for the track
    let title: String           // Track title
    let artist: String          // Track artist
    let url: String             // For online: full URL; for offline: filename (without .mp3)
    let isLocal: Bool           // true = offline/bundled, false = online/streamed
    
    /// Initializes a new TrackModel.
       /// - Parameters:
       ///   - id: Unique identifier (default: new UUID)
       ///   - title: Track title
       ///   - artist: Track artist
       ///   - url: URL string or local filename
       ///   - isLocal: true if offline/bundled, false if online/streamed
    init(id: UUID = UUID(), title: String, artist: String, url: String, isLocal: Bool) {
        self.id = id
        self.title = title
        self.artist = artist
        self.url = url
        self.isLocal = isLocal
    }
}

