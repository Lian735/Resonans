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
    @AppStorage("accentColor") private var accentRaw = AccentColorOption.purple.rawValue
    @State private var activeSheet: ActiveSheet?

    private var accent: AccentColorOption { AccentColorOption(rawValue: accentRaw) ?? .purple }

    init(image: UIImage) {
        _viewModel = StateObject(wrappedValue: RemoveBackgroundViewModel(image: image))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Preview") {
                    VStack(alignment: .center, spacing: 16) {
                        Image(uiImage: viewModel.image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        if viewModel.isLoading {
                            ProgressView("Processing…")
                                .progressViewStyle(.circular)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 12, leading: 0, bottom: 12, trailing: 0))
                }

                Section {
                    Button(action: viewModel.removeBackground) {
                        Text(viewModel.isLoading ? "Converting…" : "Remove background")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .navigationTitle("Remove background")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", action: dismiss.callAsFunction)
                }
            }
        }
        .tint(accent.color)
        .presentationDetents([.medium, .large])
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
            case .removeFailed:
                ConversionFailSheet(
                    accentColor: accent.color,
                    primaryColor: .primary,
                    onRetry: viewModel.removeBackground,
                    onDone: { activeSheet = nil }
                )
            case .removeSuccess(let image):
                SuccessBackgroundRemovalView(image: image)
            }
        }
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
    NavigationStack {
        RemoveBackgroundView(image: .logo)
    }
}
