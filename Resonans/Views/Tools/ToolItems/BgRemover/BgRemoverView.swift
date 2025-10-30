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

    init(viewModel: BgRemoverViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        List {
            Section("Get started") {
                Text("Remove backgrounds from your images using the camera or your photo library.")
                    .foregroundStyle(.secondary)

                Button {
                    viewModel.handleOpenCamera()
                } label: {
                    Label("Capture photo", systemImage: "camera")
                }

                Button {
                    viewModel.showPhotoLibrary()
                } label: {
                    Label("Choose from library", systemImage: "photo.on.rectangle")
                }
            }

            Section("Recent conversions") {
                if viewModel.recents.isEmpty {
                    Text("You'll see your converted images here.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.recents) { item in
                        RecentConversionRow(item: item) {
                            viewModel.handleRecentExport(item)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Background remover")
        .task { viewModel.reloadRecents() }
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
                AllowCameraSheet(status: status)
            }
        }
        .fullScreenCover(isPresented: $viewModel.useFullScreenSheet) {
            BgRemoverCameraView(
                cameraManager: CameraManager.shared,
                onPhotoCaptured: { image in
                    viewModel.useFullScreenSheet = false
                    viewModel.handleImageFromPhotoLibrary(image)
                },
                onClose: {
                    viewModel.useFullScreenSheet = false
                }
            )
        }
    }
}

private struct RecentConversionRow: View {
    let item: RecentItem
    let onExport: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                Text(item.duration)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            ShareLink(item: item.fileURL) {
                Image(systemName: "square.and.arrow.up")
                    .imageScale(.medium)
            }
            .buttonStyle(.plain)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(action: onExport) {
                Label("Save", systemImage: "tray.and.arrow.down")
            }
            .tint(.accentColor)
        }
    }
}

#Preview {
    NavigationStack {
        BgRemoverView(viewModel: BgRemoverViewModel())
    }
}
