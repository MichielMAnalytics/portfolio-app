import SwiftUI
import PhotosUI

struct ScreenshotImportView: View {
    @Bindable var importViewModel: ImportViewModel
    @Bindable var portfolioViewModel: PortfolioViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showCamera = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let image = importViewModel.selectedImage {
                    imagePreview(image)
                } else {
                    imagePicker
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(FolioTheme.background)
            .navigationTitle("Screenshot Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(FolioTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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

    // MARK: - Image Picker (no image selected)

    private var imagePicker: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 56))
                    .foregroundStyle(FolioTheme.labelGray)

                Text("Select a screenshot of your portfolio")
                    .font(.headline)
                    .foregroundStyle(.white)

                Text("The AI will extract your holdings\nfrom the screenshot automatically.")
                    .font(.subheadline)
                    .foregroundStyle(FolioTheme.labelGray)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    showCamera = true
                } label: {
                    Label("Take Photo", systemImage: "camera.fill")
                        .font(.body)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(FolioTheme.positive, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.black)
                }

                PhotosPicker(selection: $importViewModel.selectedPhotoItem, matching: .images) {
                    Label("Choose from Photos", systemImage: "photo.stack")
                        .font(.body)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(FolioTheme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
            .fullScreenCover(isPresented: $showCamera) {
                CameraView { image in
                    importViewModel.selectedImage = image
                }
            }
        }
    }

    // MARK: - Image Preview (image selected)

    private func imagePreview(_ image: UIImage) -> some View {
        VStack(spacing: 0) {
            // Image takes available space
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(FolioTheme.secondaryBackground, lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .padding(.top, 16)

            Spacer()

            // Bottom actions
            if importViewModel.isProcessingScreenshot {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(FolioTheme.positive)
                    Text("Analyzing screenshot...")
                        .font(.subheadline)
                        .foregroundStyle(FolioTheme.labelGray)
                }
                .frame(height: 80)
                .padding(.bottom, 32)
            } else {
                HStack(spacing: 12) {
                    Button {
                        importViewModel.resetScreenshotImport()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Change")
                        }
                        .font(.body)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(FolioTheme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                    }

                    Button {
                        Task {
                            await importViewModel.extractFromScreenshot()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "wand.and.stars")
                            Text("Extract")
                        }
                        .font(.body)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(FolioTheme.positive, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.black)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
    }
}
