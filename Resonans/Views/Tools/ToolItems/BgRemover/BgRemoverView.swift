//
//  BgRemoverView.swift
//  Resonans
//
//  Created by Kevin Dallian on 25/10/25.
//

import SwiftData
import SwiftUI
import PhotosUI

struct BgRemoverView: View {
    @Environment(\.modelContext) var modelContext
    @StateObject var viewModel: BgRemoverViewModel
    @AppStorage(AppStorageKey.Settings.accentColor) private var accentRaw = AccentColorOption.purple.rawValue
    @Environment(\.colorScheme) private var colorScheme
    private var background: Color { AppStyle.background(for: colorScheme) }
    @available(*, deprecated)
    private var primary: Color { AppStyle.primary(for: colorScheme) }
    @State var showAllRecents: Bool = false

    private var accent: AccentColorOption { AccentColorOption(rawValue: accentRaw) ?? .purple }
    
    init(viewModel: BgRemoverViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                    .padding(.horizontal, 24)
                
                Divider()
                
                VStack {
                    sourceSection
                    recentSection
                }
                .padding(.horizontal, 24)
            }
        }
        .onAppear {
            viewModel.modelContext = modelContext
            viewModel.fetchHistories()
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
                RemoveBackgroundView(
                    image: image,
                    modelContext: modelContext,
                    onSuccessRemove: {
                        viewModel.fetchHistories()
                    },
                    onRetake: {
                        viewModel.handleOpenCamera()
                    }
                )
            case .cameraNotAuthorized(let status):
                AllowCameraSheet(status: status) { isAccept in
                    withAnimation(.spring(duration: 0.3)) {
                        viewModel.useFullScreenSheet = isAccept
                    }
                }
            case .filePreview(let title, let url):
                if let uiImage = viewModel.getImageFromUrl(url) {
                    ImagePreview(primary: accent.color, title: title, image: uiImage)
                }
            case .camera:
                // Present the full-screen camera picker
                SystemCameraPicker(
                    onImagePicked: { image in
                        // This sets activeSheet = .tool(image:) internally
                        viewModel.handleImageFromPhotoLibrary(image)
                    },
                    onCancel: { /* no-op is fine; the sheet will dismiss itself */ }
                )
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .background(
            LinearGradient(
                colors: [accent.gradient.opacity(0.7), .clear],
                startPoint: .topLeading,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
    
    private var headerSection: some View {
        titleBox {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Background Remover")
                        .typography(.displaySmall, design: .rounded)
                    Text("Remove background from your images")
                        .typography(.titleMedium, color: .primary.opacity(0.7), design: .rounded)
                        .padding(.top, 4)
                }

                Spacer()

                Image(systemName: "person.and.background.dotted")
                    .typography(.custom(size: 35, weight: .medium), color: .primary)
                
            }
        }
    }
    
    private var sourceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Choose a source")
                    .typography(.titleLarge, color: .primary, design: .rounded)
                Spacer()
            }
            HStack(spacing: 16) {
                sourceOptionCard(icon: "camera.fill", title: "Camera") {
                    viewModel.handleOpenCamera()
                }

                sourceOptionCard(icon: "photo.on.rectangle.fill", title: "Library") {
                    viewModel.showPhotoLibrary()
                }
            }
        }
    }
    
    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("History")
                    .typography(.titleLarge, color: .primary, design: .rounded)
                Spacer()
            }
            
            AppCard {
                VStack(spacing: 12) {
                    if viewModel.histories.isEmpty {
                        Text("No exports yet")
                            .typography(.titleSmall, color: .primary.opacity(0.7), design: .rounded)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 40)
                    } else {
                        let prefixCount = showAllRecents ? viewModel.histories.count : 3
                        let histories = Array(viewModel.histories.prefix(prefixCount))
                        ForEach(histories.indices, id: \.self) { index in
                            let history = histories[index]
                            VStack(spacing: 12) {
                                historyCard(history)
                                if index < histories.count - 1 {
                                    Divider()
                                        .padding(.leading, 12)
                                }
                            }
                        }
                        
                        if viewModel.histories.count > 3 {
                            Button {
                                HapticsManager.shared.pulse()
                                withAnimation(.default) {
                                    showAllRecents.toggle()
                                }
                            } label: {
                                HStack {
                                    Text(showAllRecents ? "Show less" : "Show more")
                                        .typography(.bodyBold, color: .primary, design: .rounded)
                                    Image(systemName: showAllRecents ? "chevron.up" : "chevron.down")
                                        .typography(.bodyBold, color: .primary)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
    
    @ViewBuilder
    private func historyCard(_ history: BgRemovalHistory) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: AppStyle.iconCornerRadius, style: .continuous)
                    .fill(.primary.opacity(AppStyle.iconFillOpacity))

                if let url = history.fileUrl, let uiImage = viewModel.getImageFromUrl(url) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: AppStyle.iconCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppStyle.iconCornerRadius, style: .continuous)
                    .stroke(.primary.opacity(AppStyle.iconStrokeOpacity), lineWidth: 1)
            )
            
            if let url = history.fileUrl {
                HStack(spacing: 18) {
                    Button {
                        viewModel.activeSheet = .filePreview(title: history.title, url: url)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(history.title)
                                .typography(.titleMedium, color: .primary, design: .rounded)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            HStack(alignment: .center, spacing: 6) {
                                Text(history.createdAt.formatted(date: .abbreviated, time: .omitted))
                                    .typography(.caption, color: .primary)
                            }
                        }
                        Spacer()
                    }
                    optionMenu(id: history.id, url: url)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private func optionMenu(id: UUID, url: URL) -> some View {
        Menu {
            ShareLink(item: url) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            Button {
                viewModel.deleteHistory(id: id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .typography(.titleMedium, color: .primary.opacity(0.9))
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
                .padding(.vertical, 12)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private func titleBox<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
            VStack(alignment: .leading, spacing: 16) {
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    let memoryContainer: ModelContainer = .mock(for: History.self)
    let mockData: [History] = [
        .createMock(tool: .bgRemover, title: "Background 1"),
        .createMock(tool: .bgRemover, title: "Background 2"),
        .createMock(tool: .bgRemover, title: "Background 1"),
        .createMock(tool: .bgRemover, title: "Background 2")
    ]
    mockData.forEach { memoryContainer.mainContext.insert($0) }
    return NavigationStack {
        BgRemoverView(viewModel: BgRemoverViewModel())
    }
    .modelContainer(memoryContainer)
}

