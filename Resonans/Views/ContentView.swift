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
    @State private var recents: [RecentItem] = [

    ]
    @State private var showAllRecents = false

    // Bottom gallery items (raw PHAssets)
    @State private var assets: [PHAsset] = []
    private let thumbSize = CGSize(width: 200, height: 200)
    @State private var displayedItemCount = 30

    @State private var selectedTab: Int = 0
    @State private var addCardPage: Int = 0
    @State private var selectedAsset: PHAsset?

    @State private var homeScrollTrigger = false
    @State private var libraryScrollTrigger = false
    @State private var settingsScrollTrigger = false
    @State private var showHomeTopBorder = false
    @State private var showLibraryTopBorder = false

    @AppStorage("accentColor") private var accentRaw = AccentColorOption.purple.rawValue
    private var accent: AccentColorOption { AccentColorOption(rawValue: accentRaw) ?? .purple }

    @Environment(\.colorScheme) private var colorScheme
    private var background: Color { colorScheme == .dark ? .black : .white }
    private var primary: Color { colorScheme == .dark ? .white : .black }
    /// Uses white shadows in light mode and black shadows in dark mode
    private var shadowColor: Color { colorScheme == .light ? .white : .black }

    var body: some View {
        ZStack {
            background.ignoresSafeArea()
                .overlay(
                    LinearGradient(
                        colors: [accent.gradient, .clear],
                        startPoint: .topLeading,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea()
                )
            VStack(spacing: 0) {
                header
                ZStack {
                    TabView(selection: $selectedTab) {
                        ScrollViewReader { proxy in
                            ScrollView(.vertical, showsIndicators: false) {
                                VStack(spacing: 24) {
                                    Color.clear.frame(height: 0).id("top")
                                    Spacer(minLength: 0)
                                    addCard
                                        .background(
                                            GeometryReader { geo -> Color in
                                                DispatchQueue.main.async {
                                                    let show = geo.frame(in: .named("homeScroll")).minY < 0
                                                    if showHomeTopBorder != show {
                                                        withAnimation(.easeInOut(duration: 0.2)) {
                                                            showHomeTopBorder = show
                                                        }
                                                    }
                                                }
                                                return Color.clear
                                            }
                                        )
                                    recentSection
                                    Spacer(minLength: 40)
                                    // statusMessage removed
                                }
                            }
                            .coordinateSpace(name: "homeScroll")
                            .overlay(alignment: .top) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.5))
                                    .frame(height: 1)
                                    .opacity(showHomeTopBorder ? 1 : 0)
                                    .animation(.easeInOut(duration: 0.2), value: showHomeTopBorder)
                            }
                            .onChange(of: homeScrollTrigger) { _ in
                                withAnimation {
                                    proxy.scrollTo("top", anchor: .top)
                                }
                            }
                        }
                        .tag(0)
                        ScrollViewReader { proxy in
                            ScrollView {
                                LazyVStack {
                                    Color.clear.frame(height: 0).id("top")
                                    if assets.isEmpty {
                                        Text("None yet")
                                            .font(.system(size: 18, weight: .regular, design: .rounded))
                                            .foregroundStyle(primary.opacity(0.6))
                                            .padding(.top, 60)
                                    } else {
                                        BottomSheetGallery(
                                            assets: Array(assets.prefix(displayedItemCount)),
                                            onLastItemAppear: loadMoreItems,
                                            selectedAsset: $selectedAsset
                                        )
                                        .padding(.horizontal, AppStyle.horizontalPadding)
                                        .padding(.top, AppStyle.innerPadding)
                                    }
                                    Spacer()
                                }
                                .background(
                                    GeometryReader { geo -> Color in
                                        DispatchQueue.main.async {
                                            let topPadding: CGFloat = assets.isEmpty ? 60 : 20
                                            let show = geo.frame(in: .named("libraryScroll")).minY < -topPadding
                                            if showLibraryTopBorder != show {
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    showLibraryTopBorder = show
                                                }
                                            }
                                        }
                                        return Color.clear
                                    }
                                )
                            }
                            .coordinateSpace(name: "libraryScroll")
                            .overlay(alignment: .top) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.5))
                                    .frame(height: 1)
                                    .opacity(showLibraryTopBorder ? 1 : 0)
                                    .animation(.easeInOut(duration: 0.2), value: showLibraryTopBorder)
                            }
                            .onChange(of: libraryScrollTrigger) { _ in
                                withAnimation {
                                    proxy.scrollTo("top", anchor: .top)
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
                        }
                        .tag(1)
                        SettingsView(scrollToTopTrigger: $settingsScrollTrigger)
                            .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(.easeInOut(duration: 0.3), value: selectedTab)
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [background, background.opacity(0.0)]),
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
                                HapticsManager.shared.pulse()
                                showConversionSheet = true
                                convert()
                            }) {
                                Text("Extract Audio")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundColor(background)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(primary)
                                    .clipShape(Capsule())
                            }
                            .padding(.bottom, 0)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        ZStack {
                        LinearGradient(
                            gradient: Gradient(colors: [background, background.opacity(0.0)]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                        .frame(height: 80)
                        .ignoresSafeArea(edges: .bottom)
                            HStack {
                                Spacer()
                                Button(action: {
                                    HapticsManager.shared.pulse()
                                    if selectedTab == 0 {
                                        homeScrollTrigger.toggle()
                                    } else {
                                        selectedTab = 0
                                        DispatchQueue.main.async {
                                            homeScrollTrigger.toggle()
                                        }
                                    }
                                }) {
                                    Image(systemName: "house.fill")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundStyle(selectedTab == 0 ? accent.color : primary.opacity(0.5))
                                        .animation(.easeInOut(duration: 0.25), value: selectedTab)
                                }
                                Spacer()
                                Button(action: {
                                    HapticsManager.shared.pulse()
                                    if selectedTab == 1 {
                                        libraryScrollTrigger.toggle()
                                    } else {
                                        selectedTab = 1
                                        DispatchQueue.main.async {
                                            libraryScrollTrigger.toggle()
                                        }
                                    }
                                }) {
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundStyle(selectedTab == 1 ? accent.color : primary.opacity(0.5))
                                        .animation(.easeInOut(duration: 0.25), value: selectedTab)
                                }
                                Spacer()
                                Button(action: {
                                    HapticsManager.shared.pulse()
                                    if selectedTab == 2 {
                                        settingsScrollTrigger.toggle()
                                    } else {
                                        selectedTab = 2
                                        DispatchQueue.main.async {
                                            settingsScrollTrigger.toggle()
                                        }
                                    }
                                }) {
                                    Image(systemName: "gearshape.fill")
                                        .font(.system(size: 24, weight: .semibold))
                                        .foregroundStyle(selectedTab == 2 ? accent.color : primary.opacity(0.5))
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
                            .foregroundColor(primary)
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
        .tint(accent.color)
        .animation(.easeInOut(duration: 0.4), value: colorScheme)
        .animation(.easeInOut(duration: 0.4), value: accent)
        .contentShape(Rectangle())
        .onTapGesture {
            HapticsManager.shared.pulse()
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
                    .foregroundStyle(primary)
                Spacer()
            }
            .frame(maxWidth: .infinity)
                    .background(background)
        }
    }

    // MARK: - Subviews

    private var header: some View {
        HStack(alignment: .center) {
            ZStack(alignment: .leading) {
                Text("Resonans")
                    .opacity(selectedTab == 0 ? 1 : 0)
                Text("Library")
                    .opacity(selectedTab == 1 ? 1 : 0)
                Text("Settings")
                    .opacity(selectedTab == 2 ? 1 : 0)
            }
            .font(.system(size: 46, weight: .heavy, design: .rounded))
            .tracking(0.5)
            .foregroundStyle(primary)
            .padding(.leading, 22)
            .shadow(color: shadowColor.opacity(0.8), radius: 4, x: 0, y: 1)
            .animation(.easeInOut(duration: 0.25), value: selectedTab)
            Spacer()
            Button(action: {
                HapticsManager.shared.pulse()
                /* TODO: show help */
            }) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(primary)
                    .shadow(color: shadowColor.opacity(0.8), radius: 4, x: 0, y: 1)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 22)
        }
    }

    private var addCard: some View {
        GeometryReader { geo in
            let fullWidth = geo.size.width - (AppStyle.horizontalPadding * 2) // horizontal padding
            let targetWidth = (fullWidth - 16) / 2
            ZStack {
                if showSourceOptions {
                    background.opacity(0.001)
                        .onTapGesture {
                            HapticsManager.shared.pulse()
                            withAnimation(.easeInOut(duration: 0.35)) {
                                showSourceOptions = false
                            }
                        }
                }
                // Large rectangle (plus)
                ZStack {
                    RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                        .fill(primary.opacity(0.09))
                        .overlay(
                            VStack(spacing: 14) {
                                Image(systemName: "plus")
                                    .font(.system(size: 56, weight: .bold))
                                    .foregroundStyle(primary)
                                Text("Click to Extract Audio")
                                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                                    .foregroundStyle(primary)
                                
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                                .strokeBorder(primary.opacity(0.10), lineWidth: 1)
                        )
                        .frame(width: fullWidth, height: 165)
                        .shadow(color: shadowColor.opacity(0.65), radius: 26, x: 0, y: 20)
                        .shadow(color: .white.opacity(0.05), radius: 1, x: 0, y: 1)
                        .onTapGesture {
                            HapticsManager.shared.pulse()
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
                    RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                        .fill(primary.opacity(0.09))
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "doc.fill")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundStyle(primary)
                                Text("Files")
                                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                                    .foregroundStyle(primary)
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                                .strokeBorder(primary.opacity(0.10), lineWidth: 1)
                        )
                        .frame(width: targetWidth, height: 165)
                        .shadow(color: shadowColor.opacity(0.65), radius: 26, x: 0, y: 20)
                        .shadow(color: .white.opacity(0.05), radius: 1, x: 0, y: 1)
                        .onTapGesture {
                            HapticsManager.shared.pulse()
                            showFilePicker = true
                            withAnimation(.easeInOut(duration: 0.35)) {
                                showSourceOptions = false
                            }
                        }
                    // Gallery rectangle
                    RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                        .fill(primary.opacity(0.09))
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundStyle(primary)
                                Text("Gallery")
                                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                                    .foregroundStyle(primary)
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                                .strokeBorder(primary.opacity(0.10), lineWidth: 1)
                        )
                        .frame(width: targetWidth, height: 165)
                        .shadow(color: shadowColor.opacity(0.65), radius: 26, x: 0, y: 20)
                        .shadow(color: .white.opacity(0.05), radius: 1, x: 0, y: 1)
                        .onTapGesture {
                            HapticsManager.shared.pulse()
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
            .padding(.horizontal, AppStyle.horizontalPadding)
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
                .foregroundStyle(primary)
                .padding(.top, 16)
                .padding(.horizontal, AppStyle.innerPadding)

            VStack(spacing: 12) {
                if recents.isEmpty {
                    Text("None yet")
                        .font(.system(size: 18, weight: .regular, design: .rounded))
                        .foregroundStyle(primary.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    ForEach(recents.prefix(showAllRecents ? recents.count : 3)) { item in
                        RecentRow(item: item)
                            .padding(.horizontal, 12)
                    }
                    if recents.count > 3 {
                        Button(action: {
                            HapticsManager.shared.pulse()
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showAllRecents.toggle()
                            }
                        }) {
                            Text(showAllRecents ? "Show less" : "Show more")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(primary.opacity(0.8))
                        }
                        .padding(.top, 4)
                    }
                }
            }
            .padding(.top, 10)
            .padding(.bottom, 14)
            .frame(height: showAllRecents ? nil : 323)
        }
        .background(
            RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                .fill(primary.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                        .strokeBorder(primary.opacity(0.10), lineWidth: 1)
                )
                .shadow(color: shadowColor.opacity(0.55), radius: 22, x: 0, y: 14)
                .shadow(color: .white.opacity(0.05), radius: 1, x: 0, y: 1)
        )
        .padding(.horizontal, AppStyle.horizontalPadding)
        .padding(.bottom, 120)
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
