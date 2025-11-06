//
//  BgRemoverView.swift
//  Resonans
//
//  Created by Kevin Dallian on 25/10/25.
//

import SwiftUI
import PhotosUI

struct BgRemoverView: View {
    @StateObject var viewModel: BgRemoverViewModel
    @AppStorage(AppStorageKey.Settings.accentColor) private var accentRaw = AccentColorOption.purple.rawValue
    @State var showAllRecents: Bool = false

    private var accent: AccentColorOption { AccentColorOption(rawValue: accentRaw) ?? .purple }
    
    init(viewModel: BgRemoverViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                sourceSection
                recentSection
            }
            .padding(.horizontal, 24)
        }
        .sheet(item: $viewModel.activeSheet) { type in
            switch type {
            case .photoLibrary:
                PhotoLibraryPicker(
                    config: .init(
                        selectionLimit: 1,
                        filter: .images
                    ) { urls in
                        guard let firstUrl = urls.first else { return }
                        viewModel.handleImageFromPhotoPicker(url: firstUrl)
                    }
                )
            case .recents(let url):
                ExportPicker(url: url)
            case .tool(let image):
                RemoveBackgroundView(image: image)
            case .cameraNotAuthorized(let status):
                AllowCameraSheet(status: status) { isAccept in
                    withAnimation(.spring(duration: 0.3)) {
                        viewModel.useFullScreenSheet = isAccept
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $viewModel.useFullScreenSheet) {
            cameraView
        }
        .background(
            LinearGradient(
                colors: [accent.gradient, .clear],
                startPoint: .topLeading,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Background Remover")
                .typography(.titleMedium, color: .primary.opacity(0.7), design: .rounded)
            HStack {
                Text("Removes background from your images")
                    .typography(.displaySmall, design: .rounded)
                Spacer()
                Image(systemName: "photo.on.rectangle.angled")
                    .typography(.custom(size: 30, weight: .bold), color: accent.color)
            }
        }
        .padding(.top, 24)
    }
    
    private var sourceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose a source")
                .typography(.titleMedium, design: .rounded)

            HStack(spacing: 16) {
                sourceOptionCard(icon: "camera", title: "Take from Camera") {
                    viewModel.handleOpenCamera()
                }

                sourceOptionCard(icon: "photo.on.rectangle", title: "Pick from Photo Library") {
                    viewModel.showPhotoLibrary()
                }
            }
        }
    }
    
    private var recentSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent conversions")
                    .typography(.titleLarge, design: .rounded)
                    .padding(.top, 16)
                    .padding(.horizontal, 12)
                
                VStack(spacing: 12) {
                    if viewModel.recents.isEmpty {
                        Text("No exports yet")
                            .typography(.titleSmall, color: .primary.opacity(0.7), design: .rounded)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 40)
                    } else {
                        let prefixCount = showAllRecents ? viewModel.recents.count : 3
                        let recents = Array(viewModel.recents.prefix(prefixCount))

                        ForEach(recents.indices, id: \.self) { index in
                            let item = recents[index]
                            VStack(spacing: 12) {
                                RecentRow(item: item, onSave: viewModel.handleRecentExport)
                                    .padding(.horizontal, 12)
                                
                                if index < recents.count - 1 {
                                    Divider()
                                        .padding(.leading, 12)
                                }
                            }
                        }
                        
                        if viewModel.recents.count > 3 {
                            GlassButton {
                                HapticsManager.shared.pulse()
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    showAllRecents.toggle()
                                }
                            } label: {
                                Text(showAllRecents ? "Show less" : "Show more")
                                    .typography(.bodyBold, color: .primary.opacity(0.75), design: .rounded)
                            }
                            .padding(.top, 6)
                        }
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 18)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func sourceOptionCard(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticsManager.shared.pulse()
            action()
        } label: {
            AppCard {
                VStack(spacing: 12) {
                    Image(systemName: icon)
                        .typography(.custom(size: 30, weight: .semibold))
                    Text(title)
                        .typography(.titleSmall, design: .rounded)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
        }
        .buttonStyle(.plain)
    }
    
    private var cameraView: some View {
        BgRemoverCameraView(
            cameraManager: CameraManager.shared,
            onPhotoCaptured: { image in
                withAnimation(.spring(duration: 0.3)) {
                    viewModel.useFullScreenSheet = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    viewModel.handleImageFromPhotoLibrary(image)
                }
            },
            onClose: {
                withAnimation(.spring(duration: 0.3)) {
                    viewModel.useFullScreenSheet = false
                }
            }
        )
        .transition(.opacity)
        .zIndex(1)
    }
}

#Preview {
    NavigationStack {
        BgRemoverView(viewModel: BgRemoverViewModel())
    }
}
