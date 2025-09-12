import SwiftUI
import AVFoundation
import Photos

struct RecentItem: Identifiable {
    let id = UUID()
    let title: String
    let duration: String
}

struct GalleryItem: Identifiable {
    let id: String
    var thumbnail: UIImage?
    let duration: String
    let creationDate: Date
}

struct ContentView: View {
    @State private var videoURL: URL?
    @State private var showPhotoPicker = false
    @State private var showFilePicker = false
    @State private var selectedFormat: AudioFormat = .m4a
    @State private var isConverting = false
    @State private var message: String?
    @State private var showSourceSheet = false
    @State private var showToast = false
    @State private var toastColor: Color = .green
    @State private var showSourceOptions = false

    // Recents mocked for the visual 1:1
    @State private var recents: [RecentItem] = [
        .init(title: "video1827-extracted", duration: "00:18"),
        .init(title: "video1827-extracted", duration: "00:18")
    ]

    // Bottom gallery items (raw PHAssets)
    @State private var assets: [PHAsset] = []
    private let thumbSize = CGSize(width: 200, height: 200)
    @State private var displayedItemCount = 30

    @State private var selectedTab: Int = 0
    @State private var addCardPage: Int = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
                .overlay(
                    LinearGradient(colors: [Color.white.opacity(0.06), .clear], startPoint: .topLeading, endPoint: .bottom)
                        .ignoresSafeArea()
                )
            VStack(spacing: 0) {
                header
                ZStack {
                    TabView(selection: $selectedTab) {
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 24) {
                                Spacer(minLength: 0)
                                addCard
                                recentSection
                                Spacer(minLength: 40)
                                // statusMessage removed
                            }
                        }
                        .tag(0)
                        ScrollView {
                            LazyVStack {
                                BottomSheetGallery(
                                    assets: Array(assets.prefix(displayedItemCount)),
                                    onLastItemAppear: loadMoreItems
                                )
                                .padding(.horizontal, 14)
                                .padding(.top, 20)
                                Spacer()
                            }
                        }
                        .onAppear {
                            if assets.isEmpty {
                                loadGallery()
                            }
                        }
                        .tag(1)
                        ScrollView {
                            VStack {
                                Spacer(minLength: 60)
                                Text("Settings")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.8))
                                    .padding()
                                Spacer()
                            }
                        }
                        .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.3), value: selectedTab)
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.black, Color.black.opacity(0.0)]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                        .frame(height: 200) // increased height so fade starts lower
                        .allowsHitTesting(false),
                        alignment: .bottom
                    )
                    // Custom Tab Bar pinned at the bottom with gradient background
                    VStack {
                        Spacer()
                        ZStack {
                            LinearGradient(
                                gradient: Gradient(colors: [Color.black, Color.black.opacity(0.0)]),
                                startPoint: .bottom,
                                endPoint: .top
                            )
                            .frame(height: 80)
                            .ignoresSafeArea(edges: .bottom)
                            HStack {
                                Spacer()
                                Button(action: {
                                    selectedTab = 0
                                }) {
                                    Image(systemName: "house.fill")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundStyle(.white.opacity(selectedTab == 0 ? 0.9 : 0.5))
                                        .animation(.easeInOut(duration: 0.25), value: selectedTab)
                                }
                                Spacer()
                                Button(action: {
                                    selectedTab = 1
                                }) {
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundStyle(.white.opacity(selectedTab == 1 ? 0.9 : 0.5))
                                        .animation(.easeInOut(duration: 0.25), value: selectedTab)
                                }
                                Spacer()
                                Button(action: {
                                    selectedTab = 2
                                }) {
                                    Image(systemName: "gearshape.fill")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundStyle(.white.opacity(selectedTab == 2 ? 0.9 : 0.5))
                                        .animation(.easeInOut(duration: 0.25), value: selectedTab)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 40)
                            .padding(.vertical, 12)
                            .padding(.bottom, 0)
                        }
                    }
                }
            }
            // Toast overlay at the very top
            if showToast, let msg = message {
                VStack {
                    HStack {
                        Spacer()
                        Text(msg)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(toastColor.opacity(0.85))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        Spacer()
                    }
                    .padding(.top, 44) // closer to the top safe area
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation {
                            showToast = false
                        }
                    }
                }
            }
        }
        // Removed unused .confirmationDialog
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
        GeometryReader { geo in
            let fullWidth = geo.size.width - 44 // horizontal padding
            let targetWidth = (fullWidth - 16) / 2
            ZStack {
                // Large rectangle (plus)
                ZStack {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(Color.white.opacity(0.09))
                        .overlay(
                            VStack(spacing: 14) {
                                Image(systemName: "plus")
                                    .font(.system(size: 56, weight: .bold))
                                    .foregroundStyle(.white)
                                Text("Click to Extract Audio")
                                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                                
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 30, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                        )
                        .frame(width: fullWidth, height: 165)
                        .shadow(color: .black.opacity(0.65), radius: 26, x: 0, y: 20)
                        .shadow(color: .white.opacity(0.05), radius: 1, x: 0, y: 1)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.35)) {
                                showSourceOptions = true
                            }
                        }
                        .scaleEffect(showSourceOptions ? 0.75 : 1.0)
                        .animation(.spring(response: 0.45, dampingFraction: 0.6, blendDuration: 0), value: showSourceOptions)
                        .opacity(showSourceOptions ? 0.0 : 1.0)
                        .animation(.easeInOut(duration: 0.3), value: showSourceOptions)
                        .allowsHitTesting(!showSourceOptions)
                        .zIndex(showSourceOptions ? 0 : 1)
                }
                // Two small rectangles (Files and Gallery)
                HStack(spacing: 16) {
                    // Files rectangle
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(Color.white.opacity(0.09))
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "doc.fill")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundStyle(.white)
                                Text("Files")
                                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 30, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                        )
                        .frame(width: targetWidth, height: 165)
                        .shadow(color: .black.opacity(0.65), radius: 26, x: 0, y: 20)
                        .shadow(color: .white.opacity(0.05), radius: 1, x: 0, y: 1)
                        .onTapGesture {
                            showFilePicker = true
                            withAnimation(.easeInOut(duration: 0.35)) {
                                showSourceOptions = false
                            }
                        }
                    // Gallery rectangle
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(Color.white.opacity(0.09))
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundStyle(.white)
                                Text("Gallery")
                                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                                    .foregroundStyle(.white)
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 30, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                        )
                        .frame(width: targetWidth, height: 165)
                        .shadow(color: .black.opacity(0.65), radius: 26, x: 0, y: 20)
                        .shadow(color: .white.opacity(0.05), radius: 1, x: 0, y: 1)
                        .onTapGesture {
                            selectedTab = 1
                            withAnimation(.easeInOut(duration: 0.35)) {
                                showSourceOptions = false
                            }
                        }
                }
                .scaleEffect(showSourceOptions ? 1.0 : 0.75)
                .animation(.spring(response: 0.45, dampingFraction: 0.6, blendDuration: 0), value: showSourceOptions)
                .opacity(showSourceOptions ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.3), value: showSourceOptions)
                .allowsHitTesting(showSourceOptions)
                .zIndex(showSourceOptions ? 1 : 0)
            }
            .padding(.horizontal, 22)
            .frame(height: 165)
            .gesture(
                DragGesture(minimumDistance: 24, coordinateSpace: .local)
                    .onEnded { value in
                        if abs(value.translation.width) > abs(value.translation.height), abs(value.translation.width) > 36 {
                            withAnimation(.easeInOut(duration: 0.35)) {
                                showSourceOptions = false
                            }
                        }
                    }
            )
        }
        .frame(height: 165)
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

    // statusMessage is no longer needed; replaced by toast overlay

    // MARK: - Actions

    private func loadGallery() {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized || status == .limited else { return }
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
            let result = PHAsset.fetchAssets(with: fetchOptions)
            var list: [PHAsset] = []
            result.enumerateObjects { asset, _, _ in list.append(asset) }
            DispatchQueue.main.async {
                assets = list
            }
        }
    }

    private func formatDuration(_ duration: Double) -> String {
        let totalSeconds = Int(duration.rounded())
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

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
                    toastColor = .green
                case .failure(let error):
                    message = "Fehler: \(error.localizedDescription)"
                    toastColor = .red
                }
                withAnimation {
                    showToast = true
                }
            }
        }
    }

    private func loadMoreItems() {
        if displayedItemCount < assets.count {
            displayedItemCount = min(displayedItemCount + 30, assets.count)
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
    let assets: [PHAsset]
    let onLastItemAppear: () -> Void

    private let columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: 16, alignment: .center), count: 3)

    var body: some View {
        // Group assets by day (date only, ignoring time)
        let grouped = Dictionary(grouping: assets) { asset in
            asset.creationDate.map { Calendar.current.startOfDay(for: $0) } ?? Date.distantPast
        }
        let sortedDates = grouped.keys.sorted(by: >)
        LazyVStack(alignment: .leading, spacing: 18) {
            ForEach(sortedDates, id: \.self) { date in
                if let items = grouped[date] {
                    Section(header:
                        Text(dateFormatted(date))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                            .padding(.leading, 6)
                            .padding(.bottom, 4)
                    ) {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(items.indices, id: \.self) { idx in
                                let asset = items[idx]
                                let globalIndex = assets.firstIndex(where: { $0.localIdentifier == asset.localIdentifier })
                                Thumb(asset: asset)
                                    .onAppear {
                                        // Only call onLastItemAppear for the last asset in the entire assets list
                                        if let gi = globalIndex, gi == assets.count - 1 {
                                            onLastItemAppear()
                                        }
                                    }
                            }
                        }
                    }
                }
            }
        }
    }

    private func dateFormatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private struct Thumb: View {
        let asset: PHAsset
        @State private var image: UIImage?

        var body: some View {
        ZStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                        .overlay(alignment: .bottomLeading) {
                            Text(formatDuration(asset.duration))
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .padding(8)
                                .foregroundStyle(.white)
                                .shadow(color: .black.opacity(0.85), radius: 6, x: 0, y: 2)
                        }
                } else {
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 100, height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 26, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .onAppear {
                            if image == nil {
                                loadThumbnail()
                            }
                        }
                }
            }
        }

        private func loadThumbnail() {
            let manager = PHCachingImageManager()
            manager.requestImage(for: asset,
                                 targetSize: CGSize(width: 200, height: 200),
                                 contentMode: .aspectFill,
                                 options: nil) { result, _ in
                image = result
            }
        }

        private func formatDuration(_ duration: Double) -> String {
            let totalSeconds = Int(duration.rounded())
            let minutes = totalSeconds / 60
            let seconds = totalSeconds % 60
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// (No longer needed: OnAppearIfLastModifier)

#Preview { ContentView() }
