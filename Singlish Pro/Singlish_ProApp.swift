import SwiftUI

@main
struct Singlish_ProApp: App {
    @State private var selectedTab: AppTab = .converter

    var body: some Scene {
        WindowGroup {
            TabView(selection: $selectedTab) {
                ContentView()
                    .tag(AppTab.converter)
                    .tabItem {
                        Label("Converter", systemImage: "arrow.triangle.swap")
                    }

                SettingsView()
                    .tag(AppTab.settings)
                    .tabItem {
                        Label("Settings", systemImage: "gearshape")
                    }
            }
            .tint(.orange)
            .onOpenURL { url in
                guard url.scheme == "singlishlk" else { return }

                switch url.host {
                case "settings":
                    selectedTab = .settings
                default:
                    selectedTab = .converter
                }
            }
        }
    }
}

private enum AppTab {
    case converter
    case settings
}
