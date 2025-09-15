import SwiftUI

struct ConversionSettingsView: View {
    let videoURL: URL
    @Environment(\.dismiss) private var dismiss

    @AppStorage("accentColor") private var accentRaw = AccentColorOption.purple.rawValue
    private var accent: AccentColorOption { AccentColorOption(rawValue: accentRaw) ?? .purple }

    @Environment(\.colorScheme) private var colorScheme
    private var background: Color { colorScheme == .dark ? .black : .white }
    private var primary: Color { colorScheme == .dark ? .white : .black }

    @State private var selectedFormat: AudioFormat = .m4a
    @State private var isProcessing = false
    @State private var exportURL: URL?
    @State private var showExporter = false

    var body: some View {
        VStack(spacing: 24) {
            formatSection
            if isProcessing {
                ProgressView()
                    .tint(accent.color)
            }
            Button(action: convert) {
                Text("Convert & Export")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(background)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(accent.color.opacity(isProcessing ? 0.5 : 1))
                    .clipShape(Capsule())
            }
            .disabled(isProcessing)
            Spacer()
        }
        .padding(.top, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(background.ignoresSafeArea())
        .sheet(isPresented: $showExporter, onDismiss: { dismiss() }) {
            if let exportURL = exportURL {
                ExportPicker(url: exportURL)
            }
        }
    }

    private var formatSection: some View {
        settingsBox {
            Text("Format")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(primary)
            HStack(spacing: 12) {
                ForEach(AudioFormat.allCases, id: \.self) { format in
                    Text(format.rawValue)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(selectedFormat == format ? background : primary.opacity(0.8))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(selectedFormat == format ? accent.color : primary.opacity(0.1))
                        )
                        .onTapGesture {
                            HapticsManager.shared.selection()
                            selectedFormat = format
                        }
                }
            }
        }
    }

    private func convert() {
        guard !isProcessing else { return }
        isProcessing = true
        VideoToAudioConverter.convert(videoURL: videoURL, format: selectedFormat) { result in
            DispatchQueue.main.async {
                isProcessing = false
                switch result {
                case .success(let url):
                    exportURL = url
                    showExporter = true
                case .failure:
                    dismiss()
                }
            }
        }
    }

    private func settingsBox<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            content()
        }
        .padding(AppStyle.innerPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                .fill(primary.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                        .strokeBorder(primary.opacity(0.10), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.55), radius: 22, x: 0, y: 14)
                .shadow(color: colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.3), radius: 1, x: 0, y: 1)
        )
        .padding(.horizontal, AppStyle.horizontalPadding)
    }
}

struct ExportPicker: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        UIDocumentPickerViewController(forExporting: [url])
    }
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
}

#Preview {
    ConversionSettingsView(videoURL: URL(fileURLWithPath: "/tmp/test.mov"))
        .background(Color.black)
        .preferredColorScheme(.dark)
}
