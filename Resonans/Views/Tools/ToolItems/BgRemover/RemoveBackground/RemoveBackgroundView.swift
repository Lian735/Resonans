import SwiftUI
import UIKit

struct RemoveBackgroundView: View {
    @StateObject private var viewModel: RemoveBackgroundViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var activeSheet: ActiveSheet?

    @AppStorage("accentColor") private var accentRaw = AccentColorOption.purple.rawValue

    private var accentColor: Color { (AccentColorOption(rawValue: accentRaw) ?? .purple).color }

    init(image: UIImage) {
        _viewModel = StateObject(wrappedValue: RemoveBackgroundViewModel(image: image))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Image") {
                    VStack(alignment: .center, spacing: 12) {
                        ResizableImage(image: viewModel.image)
                        Text("Preview shows the exact image that will be processed.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }

                Section {
                    // Button(action: viewModel.removeBackground) {
                    //    if viewModel.isLoading {
                    //        HStack {
                    //            ProgressView()
                    //            Text("Removing background…")
                    //        }
                    //    } else {
                    //        Text("Remove background")
                    //    }
                    //}
                    //.buttonStyle(.borderedProminent)
                    //.disabled(viewModel.isLoading)
                }
            }
            .navigationTitle("Background")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $activeSheet) { type in
                switch type {
                case .removeFailed(let errorMessage):
                    AnyView(
                        ConversionFailSheet(
                            accentColor: accentColor,
                            primaryColor: .primary,
                            onRetry: {
                                activeSheet = nil
                            },
                            onDone: {
                                activeSheet = nil
                            }
                        )
                        .presentationDetents([.medium])
                        .presentationDragIndicator(.visible)
                    )
                case .removeSuccess(let image):
                    AnyView(
                        SuccessBackgroundRemovalView(image: image)
                            .presentationDetents([.medium])
                            .presentationDragIndicator(.visible)
                    )
                }
            }
            .onChange(of: viewModel.errorMessage) { newValue in
                guard let newValue, !newValue.isEmpty else { return }
                activeSheet = .removeFailed(errorMessage: newValue)
            }
            .onChange(of: viewModel.outputImage) { newImage in
                guard let newImage else { return }
                activeSheet = .removeSuccess(image: newImage)
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

private struct ResizableImage: View {
    let image: UIImage

    var body: some View {
        GeometryReader { geometry in
            let maxWidth = geometry.size.width
            let aspectRatio = image.size.height == 0 ? 1 : image.size.width / image.size.height

            Image(uiImage: image)
                .resizable()
                .aspectRatio(aspectRatio, contentMode: .fit)
                .frame(maxWidth: maxWidth)
                .frame(maxWidth: .infinity)
        }
        .frame(height: 240)
    }
}

#Preview {
    RemoveBackgroundView(image: .logo)
}
