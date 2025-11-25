//
//  SuccessSheet.swift
//  Resonans
//
//  Created by Kevin Dallian on 25/10/25.
//

import SwiftUI

struct SuccessBackgroundRemovalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(AppStorageKey.Settings.accentColor) private var accentRaw = AccentColorOption.purple.rawValue
    private var background: Color { AppStyle.background(for: colorScheme) }
    private var accent: AccentColorOption { AccentColorOption(rawValue: accentRaw) ?? .purple }
    
    let image: UIImage
    let fileUrl: URL
    let onDone: () -> Void
    
    var body: some View {
        VStack(alignment: .center) {
            HStack {
                Spacer()
                Button(action: {
                    onDone()
                    dismiss()
                }) {
                    Text("Done")
                        .typography(
                            .titleSmall,
                            color: colorScheme == .dark ? .white : .black,
                            design: .rounded
                        )
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Color.primary.opacity(0.07))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                        )
                }
            }
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
        Label(title, systemImage: systemImage)
            .typography(.titleSmall, color: foreground, design: .rounded)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
    }
}

#Preview {
    SuccessBackgroundRemovalView(
        image: .resonanslogo,
        fileUrl: URL(filePath: ""),
        onDone: {}
    )
}

