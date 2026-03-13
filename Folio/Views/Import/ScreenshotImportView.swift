import SwiftUI
import PhotosUI

struct ScreenshotImportView: View {
    @Bindable var importViewModel: ImportViewModel
    @Bindable var portfolioViewModel: PortfolioViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if let image = importViewModel.selectedImage {
                    imagePreview(image)
                } else {
                    imagePicker
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Screenshot Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        importViewModel.resetScreenshotImport()
                        dismiss()
                    }
                }
            }
            .onChange(of: importViewModel.selectedPhotoItem) { _, _ in
                Task {
                    await importViewModel.loadImage()
                }
            }
            .sheet(isPresented: $importViewModel.showExtractedReview) {
                ExtractedHoldingsReviewView(
                    holdings: $importViewModel.extractedHoldings,
                    onConfirm: { confirmed in
                        let holdings = importViewModel.createHoldingsFromExtracted()
                        portfolioViewModel.addHoldings(holdings)
                        importViewModel.importSuccessCount = holdings.count
                        importViewModel.showImportSuccess = true
                        importViewModel.showExtractedReview = false
                        importViewModel.resetScreenshotImport()
                        dismiss()
                    },
                    onCancel: {
                        importViewModel.showExtractedReview = false
                    }
                )
            }
            .alert("Error", isPresented: $importViewModel.showError) {
                Button("OK") { importViewModel.showError = false }
            } message: {
                Text(importViewModel.errorMessage ?? "An unknown error occurred")
            }
        }
    }

    private var imagePicker: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.viewfinder")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("Select a screenshot of your portfolio")
                .font(.headline)

            Text("The AI will extract your holdings from the screenshot automatically.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            PhotosPicker(selection: $importViewModel.selectedPhotoItem, matching: .screenshots) {
                Label("Choose Screenshot", systemImage: "photo.on.rectangle")
                    .font(.body)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.white)
            }
            .padding(.top, 8)

            PhotosPicker(selection: $importViewModel.selectedPhotoItem, matching: .images) {
                Label("Choose from All Photos", systemImage: "photo.stack")
                    .font(.body)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.top, 40)
    }

    private func imagePreview(_ image: UIImage) -> some View {
        VStack(spacing: 16) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 400)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.secondary.opacity(0.3), lineWidth: 1)
                )

            if importViewModel.isProcessingScreenshot {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Analyzing screenshot...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
            } else {
                HStack(spacing: 12) {
                    Button {
                        importViewModel.resetScreenshotImport()
                    } label: {
                        Label("Change", systemImage: "arrow.triangle.2.circlepath")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        Task {
                            await importViewModel.extractFromScreenshot()
                        }
                    } label: {
                        Label("Extract Holdings", systemImage: "wand.and.stars")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
    }
}
