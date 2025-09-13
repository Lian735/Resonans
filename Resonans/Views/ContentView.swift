import SwiftUI
import AVFoundation
import Photos

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
    @State private var showConversionSheet = false

    // Recent extractions
    @State private var recents: [RecentItem] = []
    @State private var showAllRecents = false

    // Bottom gallery items (raw PHAssets)
    @State private var assets: [PHAsset] = []
    private let thumbSize = CGSize(width: 200, height: 200)
    @State private var displayedItemCount = 30

    @State private var selectedTab: Int = 0
    @State private var addCardPage: Int = 0
    @State private var selectedAsset: PHAsset?

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
                                if assets.isEmpty {
                                    Text("None yet")
                                        .font(.system(size: 18, weight: .regular, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.6))
                                        .padding(.top, 60)
                                } else {
                                    BottomSheetGallery(
                                        assets: Array(assets.prefix(displayedItemCount)),
                                        onLastItemAppear: loadMoreItems,
                                        selectedAsset: $selectedAsset
                                    )
                                    .padding(.horizontal, 14)
                                    .padding(.top, 20)
                                }
                                Spacer()
                            }
                        }
                        .refreshable {
                            selectedAsset = nil
                            loadGallery()
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
                        if selectedAsset != nil {
                            Button(action: {
                                showConversionSheet = true
                                convert()
                            }) {
                                Text("Extract Audio")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Color.white)
                                    .clipShape(Capsule())
                            }
                            .padding(.bottom, 0)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
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
        .contentShape(Rectangle())
        .onTapGesture {
            if showSourceOptions {
                withAnimation(.easeInOut(duration: 0.35)) {
                    showSourceOptions = false
                }
            } else if selectedAsset != nil {
                withAnimation {
                    selectedAsset = nil
                }
            }
        }
        .onChange(of: selectedTab) { newValue in
            if showSourceOptions {
                withAnimation(.easeInOut(duration: 0.35)) {
                    showSourceOptions = false
                }
            }
            if newValue != 1 {
                withAnimation { selectedAsset = nil }
            }
        }
        // Removed unused .confirmationDialog
        .sheet(isPresented: $showPhotoPicker) {
            VideoPicker { url in
                videoURL = url
                showConversionSheet = true
                convert()
            }
        }
        .sheet(isPresented: $showFilePicker) {
            FilePicker { url in
                videoURL = url
                showConversionSheet = true
                convert()
            }
        }
        .sheet(isPresented: $showConversionSheet) {
            VStack {
                Spacer()
                Text("Conversion settings coming soon")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(Color.black)
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
                if showSourceOptions {
                    Color.black.opacity(0.001)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.35)) {
                                showSourceOptions = false
                            }
                        }
                }
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

            VStack(spacing: 12) {
                if recents.isEmpty {
                    Text("None yet")
                        .font(.system(size: 18, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    ForEach(recents.prefix(showAllRecents ? recents.count : 3)) { item in
                        RecentRow(item: item)
                            .padding(.horizontal, 12)
                    }
                    if recents.count > 3 {
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showAllRecents.toggle()
                            }
                        }) {
                            Text(showAllRecents ? "Show less" : "Show more")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 14)
            .frame(height: showAllRecents ? nil : 300)
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

    private func loadGallery(completion: (() -> Void)? = nil) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized || status == .limited else { return }
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
            let result = PHAsset.fetchAssets(with: fetchOptions)
            var list: [PHAsset] = []
            result.enumerateObjects { asset, _, _ in list.append(asset) }
            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    assets = list
                }
                completion?()
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

#Preview { ContentView() }
