import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.xaxis")
                }
                .tag(0)
            
            DirectoryView()
                .tabItem {
                    Label("Directory", systemImage: "phone.bubble.left.fill")
                }
                .tag(1)
            
            SimulatorView()
                .tabItem {
                    Label("Simulator", systemImage: "phone.badge.plus")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
            
            HelpView()
                .tabItem {
                    Label("Help", systemImage: "questionmark.circle.fill")
                }
                .tag(4)
        }
        .tint(.red) // Custom theme color
    }
}
