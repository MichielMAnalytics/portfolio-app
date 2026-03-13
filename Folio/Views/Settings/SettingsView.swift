import SwiftUI

struct SettingsView: View {
    @State var viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("LLM Provider") {
                    Picker("Active Provider", selection: $viewModel.selectedProvider) {
                        ForEach(LLMProvider.allCases) { provider in
                            Text(provider.displayName).tag(provider)
                        }
                    }

                    HStack {
                        Text("Status")
                        Spacer()
                        Text(viewModel.activeProviderKeyStatus)
                            .foregroundStyle(viewModel.hasValidAPIKey ? .green : .red)
                            .font(.caption)
                    }
                }

                Section("API Keys") {
                    apiKeyField(
                        title: "Claude API Key",
                        key: $viewModel.claudeAPIKey,
                        placeholder: LLMProvider.claude.keyPlaceholder
                    )

                    apiKeyField(
                        title: "OpenAI API Key",
                        key: $viewModel.openAIAPIKey,
                        placeholder: LLMProvider.openAI.keyPlaceholder
                    )

                    apiKeyField(
                        title: "Gemini API Key",
                        key: $viewModel.geminiAPIKey,
                        placeholder: LLMProvider.gemini.keyPlaceholder
                    )

                    Button("Save API Keys") {
                        viewModel.saveAPIKeys()
                    }
                    .fontWeight(.medium)
                }

                Section("Currency") {
                    Picker("Preferred Currency", selection: $viewModel.preferredCurrency) {
                        ForEach(SettingsViewModel.supportedCurrencies, id: \.self) { currency in
                            Text(currency).tag(currency)
                        }
                    }
                    .onChange(of: viewModel.preferredCurrency) { _, _ in
                        viewModel.saveCurrency()
                    }
                }

                Section("Security") {
                    HStack {
                        Image(systemName: viewModel.biometricSymbol)
                            .foregroundStyle(.blue)
                        Toggle(viewModel.biometricTypeDisplay, isOn: Binding(
                            get: { viewModel.isBiometricEnabled },
                            set: { _ in
                                Task {
                                    await viewModel.toggleBiometric()
                                }
                            }
                        ))
                    }

                    Text("When enabled, biometric authentication is required to open the app.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundStyle(.secondary)
                    }

                    Link(destination: URL(string: "https://www.coingecko.com")!) {
                        HStack {
                            Text("Crypto data by CoinGecko")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Data") {
                    Button("Clear Price Cache") {
                        Task {
                            await CoinGeckoService.shared.clearCache()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                viewModel.load()
            }
            .alert("Saved", isPresented: $viewModel.showSaveConfirmation) {
                Button("OK") {}
            } message: {
                Text("API keys have been securely saved to Keychain.")
            }
        }
    }

    private func apiKeyField(title: String, key: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            SecureField(placeholder, text: key)
                .textContentType(.password)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.body.monospaced())
        }
    }
}

#Preview {
    SettingsView()
}
