import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var portfolioViewModel = PortfolioViewModel()
    @State private var selectedTab = 0

    private var currency: String {
        UserDefaults.standard.string(forKey: "preferred_currency") ?? "USD"
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(viewModel: portfolioViewModel, currency: currency)
                .tabItem {
                    Label("Portfolio", systemImage: "house.fill")
                }
                .tag(0)

            ImportView(portfolioViewModel: portfolioViewModel)
                .tabItem {
                    Label("Import", systemImage: "square.and.arrow.down")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(2)
        }
        .tint(FolioTheme.positive)
        .onAppear {
            portfolioViewModel.setup(modelContext: modelContext)
            configureTabBarAppearance()
        }
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.black
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Portfolio.self, Holding.self], inMemory: true)
}
