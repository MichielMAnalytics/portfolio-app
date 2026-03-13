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
                    Label("Dashboard", systemImage: "chart.bar.fill")
                }
                .tag(0)

            HoldingsListView(viewModel: portfolioViewModel, currency: currency)
                .tabItem {
                    Label("Holdings", systemImage: "list.bullet.rectangle.fill")
                }
                .tag(1)

            ImportView(portfolioViewModel: portfolioViewModel)
                .tabItem {
                    Label("Import", systemImage: "square.and.arrow.down.fill")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .onAppear {
            portfolioViewModel.setup(modelContext: modelContext)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Portfolio.self, Holding.self], inMemory: true)
}
