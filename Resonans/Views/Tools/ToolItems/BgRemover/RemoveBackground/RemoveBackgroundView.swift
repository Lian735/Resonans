//
//  RemoveBackgroundView.swift
//  Resonans
//
//  Created by Kevin Dallian on 25/10/25.
//

import SwiftUI
import SwiftData
import PhotosUI

struct RemoveBackgroundView: View {
    @StateObject var viewModel: RemoveBackgroundViewModel
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    private var background: Color { AppStyle.background(for: colorScheme) }
    @AppStorage(AppStorageKey.Settings.accentColor) private var accentRaw = AccentColorOption.purple.rawValue
    @State private var revealProgress: CGFloat = 1
    private var accent: AccentColorOption { AccentColorOption(rawValue: accentRaw) ?? .purple }
    var onSuccessRemove: () -> Void
    var onRetake: () -> Void
    
    // App Storage for "custom" AppCard:
    @AppStorage(AppStorageKey.Settings.glassEffectActivated) private var glassEffectActivated: Bool = true
    @AppStorage(AppStorageKey.Settings.interactiveGlassActivated) private var interactiveGlassActivated: Bool = false
    @AppStorage(AppStorageKey.Settings.reduceTransparencyActivated) private var reduceTransparencyActivated: Bool = true
    
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
            Spacer()
            animatedImageSection
            Spacer()
            if let output = viewModel.outputImage, let url = viewModel.fileUrl {
                VStack(spacing: 12) {
                    Button(action: {
                        HapticsManager.shared.selection()
                        if let url = viewModel.fileUrl, let data = try? Data(contentsOf: url), let pngImage = UIImage(data: data) {
                            saveToPhotos(pngImage)
                        } else if let output = viewModel.outputImage {
                            saveToPhotos(output)
                        }
                        onSuccessRemove()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.down")
                                .foregroundStyle(Color.white)
                            Text("Save to Photos")
                                .typography(.titleSmall, color: .white, design: .rounded)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(accent.color)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    ShareLink(
                        item: url,
                        preview: SharePreview("Image", image: Image(uiImage: output))
                    ) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundStyle(accent.color)
                            Text("Share")
                                .typography(.titleSmall, color: accent.color, design: .rounded)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .stroke(accent.color.opacity(0.35), lineWidth: 1)
                                .fill(accent.color.opacity(0.07))
                        )
                    }
                    .simultaneousGesture(TapGesture().onEnded { HapticsManager.shared.selection() })
                }
            }
        }
        .padding(.top, 23)
        .padding(.horizontal, 24)
        .background(
            LinearGradient(
                colors: [accent.gradient.opacity(0.7), colorScheme == .dark ? .black : .white],
                startPoint: .topLeading,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .onAppear {
            viewModel.removeBackground()
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
                Text("Cancel")
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
    }
    
    struct TransparencyGrid: View {
        let size: CGFloat = 20

        var body: some View {
            Canvas { context, rect in
                let cols = Int(rect.width / size) + 2
                let rows = Int(rect.height / size) + 2

                for y in 0..<rows {
                    for x in 0..<cols {
                        let isDark = (x + y).isMultiple(of: 2)
                        let color = isDark ? Color.gray.opacity(0.35) : Color.gray.opacity(0.12)
                        let rect = CGRect(x: CGFloat(x) * size,
                                          y: CGFloat(y) * size,
                                          width: size,
                                          height: size)
                        context.fill(Path(rect), with: .color(color))
                    }
                }
            }
        }
    }
    
    private var animatedImageSection: some View {
        ZStack {
            //Transparency grid
            
            TransparencyGrid()
            
            // Back layer: converted output if available, else original
            if let output = viewModel.outputImage {
                Image(uiImage: output.normalizedOrientation())
                    .resizable()
                    .scaledToFit()
            } else {
                Image(uiImage: viewModel.image.normalizedOrientation())
                    .resizable()
                    .scaledToFit()
            }

            // Top layer: original image that will be masked OUT to reveal the converted result
            Image(uiImage: viewModel.image.normalizedOrientation())
                .resizable()
                .scaledToFit()
                .opacity(revealProgress)
        }
        .ignoresSafeArea()
        .onChange(of: viewModel.outputImage) { _, newValue in
            guard newValue != nil else { return }
            // Start from fully showing the original, then fade it out to reveal the output
            revealProgress = 1
            withAnimation(.easeInOut(duration: 0.6)) {
                revealProgress = 0
            }
        }
        .frame(width: 350, height: 350, alignment: .center)
        .glassEffect(
            .regular,
            in: .rect(cornerRadius: AppStyle.cornerRadius)
        )
        .mask {
            RoundedRectangle(cornerRadius: AppStyle.cornerRadius)
        }
        .contextMenu {
            if let output = viewModel.outputImage {
                Button {
                    HapticsManager.shared.selection()
                    if let url = viewModel.fileUrl, let data = try? Data(contentsOf: url), let pngImage = UIImage(data: data) {
                        saveToPhotos(pngImage)
                    } else {
                        saveToPhotos(output)
                    }
                } label: {
                    Label("Save Image", systemImage: "square.and.arrow.down")
                }
            } else {
                Label("Save Image", systemImage: "square.and.arrow.down")
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func capsuleLabel(title: String, systemImage: String, foreground: Color) -> some View {
        Label(title, systemImage: systemImage)
            .typography(.titleMedium, color: foreground)
            .padding(.vertical, 10)
            .padding(.horizontal, 24)
    }
    
    private func saveToPhotos(_ image: UIImage) {
        let save = {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        }
        if #available(iOS 14, *) {
            let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
            if status == .authorized || status == .limited { save(); return }
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { newStatus in
                if newStatus == .authorized || newStatus == .limited { save() }
            }
        } else {
            let status = PHPhotoLibrary.authorizationStatus()
            if status == .authorized { save(); return }
            PHPhotoLibrary.requestAuthorization { newStatus in
                if newStatus == .authorized { save() }
            }
        }
    }
}

extension UIImage {
    func normalizedOrientation() -> UIImage {
        if imageOrientation == .up { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalized ?? self
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

