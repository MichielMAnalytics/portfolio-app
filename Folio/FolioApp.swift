import SwiftUI
import SwiftData

@main
struct FolioApp: App {
    @State private var isUnlocked = false
    @State private var isBiometricEnabled = false

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([Portfolio.self, Holding.self])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if isBiometricEnabled && !isUnlocked {
                    lockScreen
                } else {
                    ContentView()
                }
            }
            .onAppear {
                checkBiometricState()
            }
            .preferredColorScheme(.dark)
        }
        .modelContainer(sharedModelContainer)
    }

    private var lockScreen: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 64))
                .foregroundStyle(FolioTheme.positive)

            Text("Folio is Locked")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)

            Text("Authenticate to access your portfolio")
                .font(.subheadline)
                .foregroundStyle(FolioTheme.labelGray)

            Button {
                authenticate()
            } label: {
                Label("Unlock", systemImage: "faceid")
                    .font(.body)
                    .fontWeight(.semibold)
                    .frame(width: 200)
                    .padding()
                    .background(FolioTheme.positive, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.black)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FolioTheme.background)
        .onAppear {
            authenticate()
        }
    }

    private func checkBiometricState() {
        isBiometricEnabled = UserDefaults.standard.bool(forKey: "biometric_enabled")
        if !isBiometricEnabled {
            isUnlocked = true
        }
    }

    private func authenticate() {
        Task {
            let success = await BiometricService.shared.authenticate()
            await MainActor.run {
                isUnlocked = success
            }
        }
    }
}
