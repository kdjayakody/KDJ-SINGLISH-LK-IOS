import SwiftUI

@main
struct Singlish_ProApp: App {
    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                    .tabItem {
                        Label("Converter", systemImage: "arrow.triangle.swap")
                    }

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape")
                    }
            }
            .tint(.orange)
        }
    }
}