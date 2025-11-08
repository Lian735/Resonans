//
//  RemoveBackgroundView.swift
//  Resonans
//
//  Created by Kevin Dallian on 25/10/25.
//

import SwiftUI

struct RemoveBackgroundView: View {
    @StateObject var viewModel: RemoveBackgroundViewModel
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(AppStorageKey.Settings.accentColor) private var accentRaw = AccentColorOption.purple.rawValue
    @State var activeSheet: ActiveSheet?
    private var accent: AccentColorOption { AccentColorOption(rawValue: accentRaw) ?? .purple }
    
    init(image: UIImage) {
        self._viewModel = StateObject(wrappedValue: RemoveBackgroundViewModel(image: image))
    }
    
    var body: some View {
        VStack {
            headerSection
            imageSection
            Spacer()
            footerButton
        }
        .presentationDetents([.medium])
        .padding(.top, 12)
        .padding(.horizontal, 24)
        .background(
            LinearGradient(
                colors: [accent.gradient, colorScheme == .dark ? .black : .white],
                startPoint: .topLeading,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .onChange(of: viewModel.errorMessage) { oldError, newError in
            if let newError, oldError != newError, !newError.isEmpty {
                activeSheet = .removeFailed(errorMessage: newError)
            }
        }
        .onChange(of: viewModel.outputImage) { _, newImage in
            guard let newImage else { return }
            activeSheet = .removeSuccess(image: newImage)
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
            case .removeSuccess(let image):
                SuccessBackgroundRemovalView(image: image)
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
                    Text("Done")
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
        }
        .frame(width: 250)
    }
    
    private var footerButton: some View {
        GlassButton(action: viewModel.removeBackground) {
            Text("Convert")
                .typography(.titleMedium, color: .white)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
        }
        .disabled(viewModel.isLoading)
    }
}

extension RemoveBackgroundView {
    enum ActiveSheet: Identifiable {
        case removeFailed(errorMessage: String)
        case removeSuccess(image: UIImage)
        var id: String { String(describing: self) }
    }
}

#Preview {
    struct Preview: View {
        @State var isShown: Bool = true
        
        var body: some View {
            GlassButton("Show Sheet") {
                isShown = true
            }
            .sheet(isPresented: $isShown) {
                RemoveBackgroundView(image: .resonanslogo)
            }
        }
    }
    return Preview()
}
