import SwiftUI

struct ContentView: View {
    @Environment(ThemeManager.self) private var themeManager
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem { Label("记账", systemImage: "square.and.pencil") }
                .tag(0)

            StatisticsView()
                .tabItem { Label("统计", systemImage: "chart.bar.fill") }
                .tag(1)

            AssetsView()
                .tabItem { Label("资产", systemImage: "creditcard.fill") }
                .tag(2)

            SettingsView()
                .tabItem { Label("设置", systemImage: "gearshape.fill") }
                .tag(3)
        }
    }
}
