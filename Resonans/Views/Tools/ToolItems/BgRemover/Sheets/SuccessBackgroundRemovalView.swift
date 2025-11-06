//
//  SuccessSheet.swift
//  Resonans
//
//  Created by Kevin Dallian on 25/10/25.
//

import SwiftUI

struct SuccessBackgroundRemovalView: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(AppStorageKey.Settings.accentColor) private var accentRaw = AccentColorOption.purple.rawValue
    private var accent: AccentColorOption { AccentColorOption(rawValue: accentRaw) ?? .purple }
    
    let image: UIImage
    var body: some View {
        VStack(alignment: .center) {
            Text("Success!")
                .typography(.displayLarge, color: .green)
            AppCard {
                VStack(alignment: .center) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                    Text("Final Image")
                        .typography(.displaySmall, design: .rounded)
                }
                .padding(.horizontal, 24)
            }
            if let url = saveImageToTemporaryFile(image) {
                ShareLink(
                    item: url,
                    preview: SharePreview("Image", image: Image(uiImage: image))
                ) {
                    capsuleLabel(
                        title: "Save Image",
                        systemImage: "tray.and.arrow.down",
                        foreground: accent.color
                    )
                    .background(
                        Capsule()
                            .stroke(accent.color.opacity(0.35), lineWidth: 1)
                            .fill(accent.color.opacity(0.07))
                    )
                }
            } else {
                Text("Failed to prepare image")
            }
        }
    }
    
    private func saveImageToTemporaryFile(_ image: UIImage) -> URL? {
        guard let data = image.pngData() else { return nil }
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("image.png")
        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("Error saving image:", error)
            return nil
        }
    }
    
    private func capsuleLabel(title: String, systemImage: String, foreground: Color) -> some View {
        HStack {
            Spacer()
            Label(title, systemImage: systemImage)
                .typography(.titleSmall, color: foreground, design: .rounded)
            Spacer()
        }
        .padding(.vertical, 14)
    }
}

#Preview {
    SuccessBackgroundRemovalView(image: .resonansicon)
}
