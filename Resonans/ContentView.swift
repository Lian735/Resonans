import SwiftUI
import AVFoundation

struct RecentItem: Identifiable {
    let id = UUID()
    let title: String
    let duration: String
}

struct GalleryItem: Identifiable {
    let id = UUID()
    let duration: String
}

struct ContentView: View {
    @State private var videoURL: URL?
    @State private var showPhotoPicker = false
    @State private var showFilePicker = false
    @State private var selectedFormat: AudioFormat = .m4a
    @State private var isConverting = false
    @State private var message: String?
    @State private var showSourceSheet = false

    // Recents mocked for the visual 1:1
    @State private var recents: [RecentItem] = [
        .init(title: "video1827-extracted", duration: "00:18"),
        .init(title: "video1827-extracted", duration: "00:18")
    ]

    // Bottom gallery items (2 rows × 3 cols)
    private let gallery: [GalleryItem] = [
        .init(duration: "00:14"), .init(duration: "01:56"), .init(duration: "00:01"),
        .init(duration: "00:14"), .init(duration: "01:56"), .init(duration: "00:01")
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
                .overlay(
                    LinearGradient(colors: [Color.white.opacity(0.06), .clear], startPoint: .topLeading, endPoint: .bottom)
                        .ignoresSafeArea()
                )
            VStack(spacing: 0) {
                header
                TabView {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 24) {
                            addCard
                            recentSection
                            Spacer(minLength: 40)
                            statusMessage
                        }
                    }
                    ScrollView {
                        VStack {
                            BottomSheetGallery(items: gallery)
                                .padding(.horizontal, 14)
                                .padding(.top, 20)
                            Spacer()
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
        }
        .confirmationDialog("Add from", isPresented: $showSourceSheet, titleVisibility: .hidden) {
            Button("Photos") { showPhotoPicker = true }
            Button("Files") { showFilePicker = true }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $showPhotoPicker) {
            VideoPicker { url in
                videoURL = url
                convert()
            }
        }
        .sheet(isPresented: $showFilePicker) {
            FilePicker { url in
                videoURL = url
                convert()
            }
        }
    }

    // MARK: - Subviews

    private var header: some View {
        HStack(alignment: .center) {
            Text("Resonans")
                .font(.system(size: 46, weight: .heavy, design: .rounded))
                .tracking(0.5)
                .foregroundStyle(.white)
                .padding(.leading, 12)
            Spacer()
            Button(action: { /* TODO: show help */ }) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 1)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 8)
        }
    }

    private var addCard: some View {
        Button(action: { showSourceSheet = true }) {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.white.opacity(0.09))
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                )
                .overlay(
                    VStack(spacing: 14) {
                        Image(systemName: "plus")
                            .font(.system(size: 56, weight: .bold))
                            .foregroundStyle(.white)
                        Text("click to add files")
                            .font(.system(size: 24, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .padding(.vertical, 28)
                )
                .shadow(color: .black.opacity(0.65), radius: 26, x: 0, y: 20)
                .shadow(color: .white.opacity(0.05), radius: 1, x: 0, y: 1)
                .frame(height: 230)
                .padding(.horizontal, 22)
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title inside the box
            Text("Recent extractions")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.top, 16)
                .padding(.horizontal, 20)

            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 12) {
                    ForEach(recents) { item in
                        RecentRow(item: item)
                            .padding(.horizontal, 12)
                    }
                }
                .padding(.top, 10)
                .padding(.bottom, 14)
            }
            .frame(height: 240)
        }
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.55), radius: 22, x: 0, y: 14)
                .shadow(color: .white.opacity(0.05), radius: 1, x: 0, y: 1)
        )
        .padding(.horizontal, 22)
    }

    private var statusMessage: some View {
        Group {
            if let msg = message {
                Text(msg)
                    .font(.footnote)
                    .foregroundStyle(.green)
                    .padding(.bottom, 8)
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Actions

    private func convert() {
        guard let videoURL else { return }
        isConverting = true
        message = nil
        VideoToAudioConverter.convert(videoURL: videoURL, format: selectedFormat) { result in
            DispatchQueue.main.async {
                isConverting = false
                switch result {
                case .success(let url):
                    let item = RecentItem(title: url.deletingPathExtension().lastPathComponent, duration: "00:18")
                    recents.insert(item, at: 0)
                    message = "Gespeichert: \(url.lastPathComponent)"
                case .failure(let error):
                    message = "Fehler: \(error.localizedDescription)"
                }
            }
        }
    }
}

private struct RecentRow: View {
    let item: RecentItem

    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.14))
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                )
                .shadow(color: .black.opacity(0.45), radius: 12, x: 0, y: 6)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(item.duration)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.white.opacity(0.8))
            }
            Spacer()
            Button(action: { /* TODO: share/download */ }) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(0.12))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.16))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.55), radius: 18, x: 0, y: 10)
        .shadow(color: .white.opacity(0.06), radius: 1, x: 0, y: 1)
    }
}

private struct BottomSheetGallery: View {
    let items: [GalleryItem]

    private let columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: 16, alignment: .center), count: 3)

    var body: some View {
        VStack(spacing: 12) {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(items) { item in
                    Thumb(duration: item.duration)
                }
            }
        }
    }

    private struct Thumb: View {
        let duration: String
        var body: some View {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(LinearGradient(colors: [.white.opacity(0.08), .white.opacity(0.18)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(height: 100)
                .overlay(alignment: .bottomLeading) {
                    Text(duration)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .padding(8)
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.85), radius: 6, x: 0, y: 2)
                }
        }
    }
}

#Preview { ContentView() }
