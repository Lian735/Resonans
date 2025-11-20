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
    let fileUrl: URL
    
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
            ShareLink(
                item: fileUrl,
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
    SuccessBackgroundRemovalView(image: .resonanslogo, fileUrl: URL(filePath: ""))
}
