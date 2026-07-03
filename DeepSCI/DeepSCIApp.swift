import SwiftUI

@main
struct DeepSCIApp: App {
    @StateObject private var spamManager = SpamManager.shared
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(spamManager)
                .preferredColorScheme(.dark) // Dark mode configuration
        }
    }
}
