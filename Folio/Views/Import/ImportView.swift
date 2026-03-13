import SwiftUI

struct ImportView: View {
    @Bindable var portfolioViewModel: PortfolioViewModel
    @State private var importViewModel = ImportViewModel()
    @State private var showScreenshotImport = false
    @State private var showCSVImport = false
    @State private var showAddHolding = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    importCard(
                        icon: "camera.viewfinder",
                        iconColor: .blue,
                        title: "Screenshot Import",
                        description: "Take or select a screenshot of your portfolio. AI will extract your holdings automatically.",
                        buttonTitle: "Import from Screenshot"
                    ) {
                        showScreenshotImport = true
                    }

                    importCard(
                        icon: "doc.text",
                        iconColor: .green,
                        title: "CSV Import",
                        description: "Import holdings from a CSV file. Supports Trade Republic and other broker exports.",
                        buttonTitle: "Import from CSV"
                    ) {
                        showCSVImport = true
                    }

                    importCard(
                        icon: "plus.circle",
                        iconColor: .orange,
                        title: "Manual Entry",
                        description: "Add a holding manually with full control over all details.",
                        buttonTitle: "Add Manually"
                    ) {
                        showAddHolding = true
                    }

                    infoSection
                }
                .padding()
            }
            .navigationTitle("Import")
            .sheet(isPresented: $showScreenshotImport) {
                ScreenshotImportView(
                    importViewModel: importViewModel,
                    portfolioViewModel: portfolioViewModel
                )
            }
            .sheet(isPresented: $showCSVImport) {
                CSVImportView(
                    importViewModel: importViewModel,
                    portfolioViewModel: portfolioViewModel
                )
            }
            .sheet(isPresented: $showAddHolding) {
                NavigationStack {
                    AddHoldingView(viewModel: AddHoldingViewModel()) {
                        // save handled below
                    }
                    .navigationTitle("Add Holding")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Cancel") {
                                showAddHolding = false
                            }
                        }
                    }
                }
            }
            .alert("Import Successful", isPresented: $importViewModel.showImportSuccess) {
                Button("OK") { importViewModel.showImportSuccess = false }
            } message: {
                Text("\(importViewModel.importSuccessCount) holdings have been imported successfully.")
            }
        }
    }

    private func importCard(
        icon: String,
        iconColor: Color,
        title: String,
        description: String,
        buttonTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(iconColor)
                    .frame(width: 44, height: 44)
                    .background(iconColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Button(action: action) {
                Text(buttonTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(iconColor, in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.white)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("How it works", systemImage: "info.circle")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                infoRow(number: "1", text: "Choose an import method above")
                infoRow(number: "2", text: "Select your file or screenshot")
                infoRow(number: "3", text: "Review and edit extracted holdings")
                infoRow(number: "4", text: "Confirm to add to your portfolio")
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func infoRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.caption)
                .fontWeight(.bold)
                .frame(width: 20, height: 20)
                .background(.blue.opacity(0.15), in: Circle())
                .foregroundStyle(.blue)

            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
