import SwiftUI

//To Identify which view is currently open
class AppCoordinator: ObservableObject {
    @Published var currentView: AppView = .player
    
    enum AppView {
        case player
        case settings
    }
    
    func navigate(to view: AppView) {
        currentView = view
    }
}
