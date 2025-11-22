//
//  RemoveBackgroundView.swift
//  Resonans
//
//  Created by Kevin Dallian on 25/10/25.
//

import SwiftUI
import SwiftData

struct RemoveBackgroundView: View {
    @StateObject var viewModel: RemoveBackgroundViewModel
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(AppStorageKey.Settings.accentColor) private var accentRaw = AccentColorOption.purple.rawValue
    @State var activeSheet: ActiveSheet?
    private var accent: AccentColorOption { AccentColorOption(rawValue: accentRaw) ?? .purple }
    var onSuccessRemove: () -> Void
    var onRetake: () -> Void
    
    init(
        image: UIImage,
        modelContext: ModelContext,
        onSuccessRemove: @escaping ()-> Void,
        onRetake: @escaping ()-> Void
    ) {
        self._viewModel = StateObject(wrappedValue: RemoveBackgroundViewModel(image: image, modelContext: modelContext))
        self.onSuccessRemove = onSuccessRemove
        self.onRetake = onRetake
    }
    
    var body: some View {
        VStack {
            headerSection
            imageSection
            Spacer()
            footerButton
        }
        .padding(.top, 12)
        .padding(.horizontal, 24)
        .background(
            LinearGradient(
                colors: [accent.gradient.opacity(0.7), .clear],
                startPoint: .bottomTrailing,
                endPoint: .top
            )
            .ignoresSafeArea()
        )
        .onChange(of: viewModel.errorMessage) { oldError, newError in
            if let newError, oldError != newError, !newError.isEmpty {
                activeSheet = .removeFailed(errorMessage: newError)
            }
        }
        .onChange(of: viewModel.outputImage) { _, newImage in
            guard let newImage, let url = viewModel.fileUrl else { return }
            activeSheet = .removeSuccess(image: newImage, fileUrl: url)
        }
        .sheet(item: $activeSheet) { type in
            switch type {
            case .removeFailed(_):
                ConversionFailSheet(
                    accentColor: accent.color,
                    primaryColor: .primary,
                    onRetry: {},
                    onDone: { activeSheet = nil }
                )
            case .removeSuccess(let image, let fileUrl):
                SuccessBackgroundRemovalView(
                    image: image,
                    fileUrl: fileUrl,
                    onDone: {
                        dismiss()
                        onSuccessRemove()
                    }
                )
            }
        }
    }
    
    private var headerSection: some View {
        HStack {
            Text("Background")
                .typography(.displayMedium, design: .rounded)
            Spacer()
            Button(action: {
                HapticsManager.shared.selection()
                dismiss()
            }) {
                AppCard(isMaxWidth: false) {
                    Text("Cancel")
                        .typography(.titleSmall, design: .rounded)
                }
            }
        }
    }
    
    private var imageSection: some View {
        AppCard {
            VStack {
                Image(uiImage: viewModel.image)
                    .resizable()
                    .scaledToFit()
                Text("Image")
                    .typography(.titleLarge)
            }
            .padding(.horizontal, 24)
        }
    }
    
    private var footerButton: some View {
        HStack {
            Button {
                dismiss()
                onRetake()
            } label: {
                AppCard {
                    Text("Retake")
                        .typography(.titleMedium, color: .primary)
                }
            }
            Button(action: viewModel.removeBackground) {
                AppCard {
                    Text("Convert")
                        .typography(.titleMedium, color: .primary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .disabled(viewModel.isLoading)
    }
}

extension RemoveBackgroundView {
    enum ActiveSheet: Identifiable {
        case removeFailed(errorMessage: String)
        case removeSuccess(image: UIImage, fileUrl: URL)
        var id: String { String(describing: self) }
    }
}

#Preview {
    struct Preview: View {
        @State var isShown: Bool = true
        let modelContainer: ModelContainer = .mock(for: History.self)
        
        var body: some View {
            GlassButton("Show Sheet") {
                isShown = true
            }
            .sheet(isPresented: $isShown) {
                RemoveBackgroundView(
                    image: .resonanslogo,
                    modelContext: modelContainer.mainContext,
                    onSuccessRemove: { print("onSuccessRemove") },
                    onRetake: { print("onRetake") }
                )
            }
        }
    }
    return Preview()
}
