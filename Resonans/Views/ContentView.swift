import SwiftUI
import AVFoundation
import Photos

enum MainTab: String, CaseIterable, Identifiable {
    case home
    case gallery
    case settings

    var id: String { rawValue }

    var navigationTitle: String {
        switch self {
        case .home: return "Resonans"
        case .gallery: return "Library"
        case .settings: return "Settings"
        }
    }

    var tagline: String {
        switch self {
        case .home: return "Convert clips into studio-grade audio."
        case .gallery: return "Browse and prepare your recent captures."
        case .settings: return "Tailor Resonans to your workflow."
        }
    }

    var iconName: String {
        switch self {
        case .home: return "house.fill"
        case .gallery: return "photo.on.rectangle.angled"
        case .settings: return "gearshape.fill"
        }
    }

    var shortTitle: String {
        switch self {
        case .home: return "Home"
        case .gallery: return "Gallery"
        case .settings: return "Settings"
        }
    }
}

private struct ToastData: Identifiable {
    let id = UUID()
    let message: String
    let tint: Color
    let iconName: String
}

private enum PickerType: Identifiable {
    case photoLibrary
    case files

    var id: String {
        switch self {
        case .photoLibrary: return "photoLibrary"
        case .files: return "files"
        }
    }
}

struct ContentView: View {
    @State private var selectedTab: MainTab = .home

    @State private var videoURL: URL?
    @State private var showConversionSheet = false

    @State private var activePicker: PickerType?
    @State private var showSourceSheet = false

    @State private var recents: [RecentItem] = []
    @State private var showAllRecents = false

    @State private var assets: [PHAsset] = []
    @State private var displayedItemCount = 30
    @State private var selectedAsset: PHAsset?
    @State private var isLoadingGallery = false

    @State private var homeScrollTrigger = false
    @State private var galleryScrollTrigger = false
    @State private var settingsScrollTrigger = false

    @State private var toastData: ToastData?

    @AppStorage("accentColor") private var accentRaw = AccentColorOption.purple.rawValue
    private var accent: AccentColorOption { AccentColorOption(rawValue: accentRaw) ?? .purple }

    @Environment(\.colorScheme) private var colorScheme
    private var background: Color { AppStyle.background(for: colorScheme) }
    private var primary: Color { AppStyle.primary(for: colorScheme) }

    private static let selectionDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        ZStack(alignment: .top) {
            background
                .ignoresSafeArea()
                .overlay(
                    LinearGradient(
                        colors: [accent.gradient.opacity(0.45), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                )

            VStack(spacing: 0) {
                ResonansNavigationBar(
                    title: selectedTab.navigationTitle,
                    subtitle: selectedTab.tagline,
                    accentColor: accent.color,
                    primaryColor: primary,
                    onHelp: showHelp
                )

                Picker("Tab", selection: $selectedTab) {
                    ForEach(MainTab.allCases) { tab in
                        Text(tab.shortTitle).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, AppStyle.horizontalPadding)
                .padding(.top, 6)

                Group {
                    switch selectedTab {
                    case .home:
                        homeTab
                    case .gallery:
                        galleryTab
                    case .settings:
                        SettingsView(scrollToTopTrigger: $settingsScrollTrigger)
                            .padding(.top, 12)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .animation(.easeInOut(duration: 0.25), value: selectedTab)
            }
        }
        .overlay(alignment: .top) {
            if let toast = toastData {
                InlineToastView(message: toast.message, tint: toast.tint, primaryColor: primary, iconName: toast.iconName)
                    .padding(.horizontal, AppStyle.horizontalPadding)
                    .padding(.top, 10)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                if let asset = selectedAsset {
                    SelectionSummaryView(
                        title: asset.creationDate.map { Self.selectionDateFormatter.string(from: $0) } ?? "Selected clip",
                        subtitle: selectionSubtitle(for: asset),
                        isReady: videoURL != nil,
                        accentColor: accent.color,
                        primaryColor: primary,
                        onClear: {
                            HapticsManager.shared.selection()
                            clearSelection()
                        },
                        onConvert: {
                            HapticsManager.shared.pulse()
                            guard videoURL != nil else { return }
                            showConversionSheet = true
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                ResonansTabBar(
                    selectedTab: $selectedTab,
                    accentColor: accent.color,
                    primaryColor: primary,
                    onReselect: { tab in
                        switch tab {
                        case .home:
                            homeScrollTrigger.toggle()
                        case .gallery:
                            galleryScrollTrigger.toggle()
                        case .settings:
                            settingsScrollTrigger.toggle()
                        }
                    }
                )
            }
            .padding(.horizontal, AppStyle.horizontalPadding)
            .padding(.top, 12)
            .padding(.bottom, 20)
            .background(
                LinearGradient(
                    colors: [background.opacity(colorScheme == .dark ? 0.92 : 0.9), background.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(edges: .bottom)
            )
        }
        .onChange(of: selectedTab) { _, newValue in
            if newValue != .gallery {
                clearSelection()
            }
        }
        .onChange(of: selectedAsset) { _, asset in
            guard let asset = asset else {
                if !showConversionSheet { videoURL = nil }
                return
            }

            videoURL = nil
            requestURL(for: asset)
            presentToast(message: "Clip ready – tap Extract to continue.", tint: accent.color)
        }
        .sheet(isPresented: $showSourceSheet) {
            SourceSelectionSheet(
                accentColor: accent.color,
                primaryColor: primary,
                onImportFromLibrary: {
                    showSourceSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        activePicker = .photoLibrary
                    }
                },
                onImportFromFiles: {
                    showSourceSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        activePicker = .files
                    }
                },
                onOpenGallery: {
                    showSourceSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        selectedTab = .gallery
                    }
                }
            )
            .presentationDetents([.height(320), .large])
        }
        .sheet(item: $activePicker) { picker in
            switch picker {
            case .photoLibrary:
                VideoPicker { url in
                    activePicker = nil
                    handleExternalSelection(url)
                }
            case .files:
                FilePicker { url in
                    activePicker = nil
                    handleExternalSelection(url)
                }
            }
        }
        .sheet(
            isPresented: $showConversionSheet,
            onDismiss: {
                clearSelection()
                videoURL = nil
            }
        ) {
            if let url = videoURL {
                ConversionSettingsView(videoURL: url)
            }
        }
        .task {
            if assets.isEmpty {
                loadGallery()
            }
        }
        .tint(accent.color)
    }

    private var homeTab: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 28) {
                    Color.clear
                        .frame(height: 1)
                        .id("home-top")

                    heroCard
                    metricsSection
                    recentSection
                }
                .padding(.horizontal, AppStyle.horizontalPadding)
                .padding(.top, 20)
                .padding(.bottom, 160)
            }
            .onChange(of: homeScrollTrigger) { _, _ in
                withAnimation(.easeInOut(duration: 0.35)) {
                    proxy.scrollTo("home-top", anchor: .top)
                }
            }
        }
    }

    private var galleryTab: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    Color.clear
                        .frame(height: 1)
                        .id("gallery-top")

                    galleryHeader

                    if assets.isEmpty {
                        VStack(spacing: 12) {
                            if isLoadingGallery {
                                ProgressView()
                                    .progressViewStyle(.circular)
                            }
                            Text("Allow access to your Photos library to see your clips here.")
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundStyle(primary.opacity(0.7))
                                .multilineTextAlignment(.center)

                            Button("Request Access") {
                                HapticsManager.shared.selection()
                                loadGallery()
                            }
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(accent.color.opacity(0.2))
                            .clipShape(Capsule())
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .appCardStyle(
                            primary: primary,
                            colorScheme: colorScheme,
                            fillOpacity: AppStyle.subtleCardFillOpacity,
                            shadowLevel: .medium
                        )
                    } else {
                        BottomSheetGallery(
                            assets: Array(assets.prefix(displayedItemCount)),
                            onLastItemAppear: loadMoreItems,
                            selectedAsset: $selectedAsset
                        )
                        .padding(.horizontal, AppStyle.horizontalPadding)
                    }
                }
                .padding(.top, 20)
                .padding(.bottom, 160)
            }
            .refreshable {
                clearSelection()
                loadGallery()
            }
            .onChange(of: galleryScrollTrigger) { _, _ in
                withAnimation(.easeInOut(duration: 0.35)) {
                    proxy.scrollTo("gallery-top", anchor: .top)
                }
            }
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Professional extraction")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(primary)
                        .lineLimit(2)

                    Text("Select a source below to transform any video into a polished audio file in seconds.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(primary.opacity(0.75))
                        .lineLimit(3)
                }

                Spacer()

                Image(systemName: "waveform.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 54, height: 54)
                    .foregroundStyle(accent.color)
                    .shadow(color: accent.color.opacity(0.4), radius: 12, x: 0, y: 6)
            }

            Button {
                HapticsManager.shared.pulse()
                showSourceSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("Start new conversion")
                        .fontWeight(.semibold)
                }
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(accent.color)
                .clipShape(RoundedRectangle(cornerRadius: AppStyle.compactCornerRadius, style: .continuous))
            }
            .buttonStyle(.plain)

            HStack(spacing: 12) {
                quickActionButton(
                    title: "Files",
                    subtitle: "Import documents",
                    icon: "folder.fill"
                ) {
                    HapticsManager.shared.selection()
                    activePicker = .files
                }

                quickActionButton(
                    title: "Photos",
                    subtitle: "Open library",
                    icon: "photo.fill"
                ) {
                    HapticsManager.shared.selection()
                    activePicker = .photoLibrary
                }

                quickActionButton(
                    title: "Gallery",
                    subtitle: "Recent clips",
                    icon: "rectangle.stack.fill"
                ) {
                    HapticsManager.shared.selection()
                    selectedTab = .gallery
                }
            }
        }
        .padding(24)
        .appCardStyle(
            primary: primary,
            colorScheme: colorScheme,
            fillOpacity: AppStyle.cardFillOpacity,
            strokeOpacity: AppStyle.strokeOpacity,
            shadowLevel: .large
        )
    }

    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(primary.opacity(0.8))

            HStack(spacing: 16) {
                MetricCard(
                    title: "Gallery clips",
                    value: assets.isEmpty ? "—" : "\(assets.count)",
                    caption: "Ready for extraction",
                    accentColor: accent.color,
                    primaryColor: primary
                )

                MetricCard(
                    title: "Recents",
                    value: recents.isEmpty ? "—" : "\(recents.count)",
                    caption: "Finished exports",
                    accentColor: accent.color,
                    primaryColor: primary
                )
            }
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent conversions")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(primary)
                Spacer()
                if recents.count > 3 {
                    Button(showAllRecents ? "Show less" : "Show all") {
                        HapticsManager.shared.selection()
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showAllRecents.toggle()
                        }
                    }
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(accent.color)
                    .buttonStyle(.plain)
                }
            }

            if recents.isEmpty {
                Text("Your finished conversions will appear here for quick access.")
                    .font(.system(size: 15))
                    .foregroundStyle(primary.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: AppStyle.compactCornerRadius, style: .continuous)
                            .stroke(primary.opacity(0.08), lineWidth: 1)
                    )
            } else {
                VStack(spacing: 12) {
                    ForEach(recents.prefix(showAllRecents ? recents.count : 3)) { item in
                        RecentRow(item: item)
                    }
                }
            }
        }
        .padding(24)
        .appCardStyle(
            primary: primary,
            colorScheme: colorScheme,
            fillOpacity: AppStyle.subtleCardFillOpacity,
            shadowLevel: .medium
        )
    }

    private var galleryHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Capture library")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(primary)

            Text("Select a video to stage it for conversion. Pull to refresh if you don't see your latest clip.")
                .font(.system(size: 15))
                .foregroundStyle(primary.opacity(0.7))
        }
        .padding(.horizontal, AppStyle.horizontalPadding)
    }

    private func quickActionButton(title: String, subtitle: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(accent.color)
                    .frame(width: 34, height: 34)
                    .background(accent.color.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(primary)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(primary.opacity(0.6))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: AppStyle.compactCornerRadius, style: .continuous)
                    .fill(primary.opacity(AppStyle.compactCardFillOpacity))
            )
        }
        .buttonStyle(.plain)
    }

    private func selectionSubtitle(for asset: PHAsset) -> String {
        let durationText = formatDuration(asset.duration)
        if asset.pixelWidth > 0 && asset.pixelHeight > 0 {
            return "\(durationText) • \(asset.pixelWidth)x\(asset.pixelHeight)"
        }
        return durationText
    }

    private func formatDuration(_ duration: Double) -> String {
        let totalSeconds = Int(duration.rounded())
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func loadMoreItems() {
        guard displayedItemCount < assets.count else { return }
        displayedItemCount = min(displayedItemCount + 30, assets.count)
    }

    private func loadGallery() {
        isLoadingGallery = true
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    isLoadingGallery = false
                    presentToast(message: "Photos access is required to browse your videos.", tint: .red, icon: "exclamationmark.triangle.fill")
                }
                return
            }

            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.video.rawValue)
            let result = PHAsset.fetchAssets(with: fetchOptions)
            var list: [PHAsset] = []
            result.enumerateObjects { asset, _, _ in list.append(asset) }

            DispatchQueue.main.async {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                    assets = list
                    displayedItemCount = min(30, list.count)
                }
                isLoadingGallery = false
            }
        }
    }

    private func requestURL(for asset: PHAsset) {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
            guard let urlAsset = avAsset as? AVURLAsset else { return }
            DispatchQueue.main.async {
                videoURL = urlAsset.url
            }
        }
    }

    private func handleExternalSelection(_ url: URL) {
        videoURL = url
        presentToast(message: "Video ready – configure your export.", tint: accent.color)
        showConversionSheet = true
    }

    private func clearSelection() {
        if selectedAsset != nil {
            withAnimation(.easeInOut(duration: 0.25)) {
                selectedAsset = nil
            }
        }
        if !showConversionSheet {
            videoURL = nil
        }
    }

    private func presentToast(message: String, tint: Color, icon: String = "checkmark.seal.fill") {
        let data = ToastData(message: message, tint: tint, iconName: icon)
        withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
            toastData = data
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if toastData?.id == data.id {
                withAnimation(.easeInOut(duration: 0.3)) {
                    toastData = nil
                }
            }
        }
    }

    private func showHelp() {
        presentToast(message: "Help center coming soon.", tint: accent.color)
        HapticsManager.shared.selection()
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let caption: String
    let accentColor: Color
    let primaryColor: Color

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(primaryColor.opacity(0.65))

            Text(value)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(primaryColor)

            Text(caption)
                .font(.system(size: 12))
                .foregroundStyle(primaryColor.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .appCardStyle(
            primary: primaryColor,
            colorScheme: colorScheme,
            cornerRadius: AppStyle.compactCornerRadius,
            fillOpacity: AppStyle.compactCardFillOpacity,
            shadowLevel: .small
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppStyle.compactCornerRadius, style: .continuous)
                .stroke(accentColor.opacity(0.05), lineWidth: 1)
        )
    }
}

private struct SelectionSummaryView: View {
    let title: String
    let subtitle: String
    let isReady: Bool
    let accentColor: Color
    let primaryColor: Color
    let onClear: () -> Void
    let onConvert: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(primaryColor)
                        .lineLimit(2)

                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(primaryColor.opacity(0.7))
                }

                Spacer()

                Button {
                    onClear()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(primaryColor.opacity(0.7))
                        .padding(8)
                        .background(primaryColor.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            HStack {
                if isReady {
                    Label("Ready to convert", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(accentColor)
                } else {
                    HStack(spacing: 8) {
                        ProgressView()
                            .progressViewStyle(.circular)
                        Text("Preparing clip…")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(primaryColor.opacity(0.7))
                    }
                }

                Spacer()

                Button {
                    onConvert()
                } label: {
                    Text("Extract audio")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(isReady ? primaryColor : primaryColor.opacity(0.6))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(isReady ? accentColor : accentColor.opacity(0.2))
                        )
                }
                .buttonStyle(.plain)
                .disabled(!isReady)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: AppStyle.compactCornerRadius, style: .continuous)
                .fill(primaryColor.opacity(AppStyle.cardFillOpacity))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppStyle.compactCornerRadius, style: .continuous)
                .stroke(primaryColor.opacity(AppStyle.strokeOpacity), lineWidth: 1)
        )
    }
}

#Preview {
    ContentView()
}
