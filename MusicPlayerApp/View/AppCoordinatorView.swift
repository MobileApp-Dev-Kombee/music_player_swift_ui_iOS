//
//  AppCoordinatorView.swift
//  MusicPlayerApp
//
//  Created by iMac on 02/05/25.
//

import SwiftUI

/// Main Intial View View
struct AppCoordinatorView: View {
    @StateObject private var coordinator = AppCoordinator()
    @StateObject private var viewModel = MusicPlayerViewModel(audioService: AudioService())
    
    var body: some View {
        NavigationView {
            switch coordinator.currentView {
            case .player:
                PlayerView(viewModel: viewModel)
                    .navigationBarItems(trailing: settingsButton)
            case .settings:
                SettingsView()
                    .navigationBarItems(leading: backButton)
            }
        }
    }
    
    private var settingsButton: some View {
        Button(action: {
            coordinator.navigate(to: .settings)
        }) {
            Image(systemName: "gear")
                .foregroundColor(.primary)
        }
        .accessibilityLabel("Settings")
    }
    
    private var backButton: some View {
        Button(action: {
            coordinator.navigate(to: .player)
        }) {
            Image(systemName: "chevron.left")
                .foregroundColor(.primary)
        }
        .accessibilityLabel("Back")
    }
}

struct SettingsView: View {
    var body: some View {
        Text(AppConstants.Strings.settings)
            .navigationTitle("Settings")
    }
}

#Preview {
    AppCoordinatorView()
}

