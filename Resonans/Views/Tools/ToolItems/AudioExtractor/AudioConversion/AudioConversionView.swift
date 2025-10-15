import SwiftUI
import AVFoundation
import UIKit

struct AudioConversionView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("accentColor") private var accentRaw = AccentColorOption.purple.rawValue
    private var accent: AccentColorOption { AccentColorOption(rawValue: accentRaw) ?? .purple }

    @Environment(\.colorScheme) private var colorScheme
    private var background: Color { AppStyle.background(for: colorScheme) }
    @available(*, deprecated)
    private var primary: Color { AppStyle.primary(for: colorScheme) }
    
    @StateObject var viewModel: AudioConversionViewModel
    @State private var isProcessing = false
    @State private var progressValue: Double = 0
    @State private var showAdvanced = false
    // Example advanced settings state
    @State private var showBitrateInfo = false
    @State private var activeSheet: ActiveSheet?
    @State private var debounceTask: Task<Void, Never>?

    private let idealPreviewSize: CGFloat = 140
    @State private var resolvedPreviewSize: CGFloat = 140
    
    init(viewModel: AudioConversionViewModel, videoUrl: URL) {
        viewModel.videoURL = videoUrl
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    private var originalFormatLabel: String {
        let ext = viewModel.videoURL.pathExtension.uppercased()
        return ext.isEmpty ? "UNKNOWN" : ext
    }

    private var clampedProgress: Double {
        min(max(progressValue, 0), 1)
    }

    var body: some View {
        mainScrollView
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(backgroundGradient)
            .safeAreaInset(edge: .bottom) { footer }
            .sheet(item: $activeSheet) { sheetType in
                switch sheetType {
                case .success(let exportUrl):
                    // TODO: Make a reusable sheet
                    ConversionSuccessSheet(
                        exportURL: exportUrl,
                        accentColor: accent.color,
                        primaryColor: primary,
                        onSave: { activeSheet = .exporter(exportUrl) },
                        onDone: { activeSheet = nil }
                    )
                case .exporter(let exportUrl):
                    ExportPicker(url: exportUrl)
                case .fail:
                    ConversionFailSheet(
                        accentColor: accent.color,
                        primaryColor: primary,
                        onRetry: { },
                        onDone: { activeSheet = nil }
                    )
                }
            }
            .onChange(
                of: viewModel.audioStatus,
                { oldStatus, newStatus in
                    guard oldStatus != newStatus else { return }
                    switch newStatus {
                    case .initiate:
                        break
                    case .failed:
                        isProcessing = false
                        dismiss()
                    case .inprogress(let progress):
                        debounceTask?.cancel()
                        debounceTask = Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                            withAnimation(.easeInOut(duration: 0.15)) {
                                progressValue = progress
                            }
                        }
                    case .completed(let url):
                        isProcessing = false
                        saveAudioToCache(tempUrl: url)
                    }
                }
            )
            .onAppear {
                if !viewModel.isLoadedAudioMetadata {
                    viewModel.loadAudioProperties()
                }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(false)
    }

    private var mainScrollView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                headerRow
                previewSection
                Spacer(minLength: 20)
                settingsSection
            }
            .padding(.horizontal, AppStyle.horizontalPadding)
            .padding(.bottom, 160)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [accent.gradient, colorScheme == .dark ? .black : .white],
            startPoint: .topLeading,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var headerRow: some View {
        HStack {
            Text("Extract audio")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(primary)

            Spacer()

            Button(action: {
                HapticsManager.shared.selection()
                dismiss()
            }) {
                Text("Done")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(primary.opacity(0.07))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(primary.opacity(0.15), lineWidth: 1)
                    )
                    .shadow(ShadowConfiguration.smallConfiguration(for: colorScheme))
            }
        }
        .padding(.top, 18)
        .padding(.bottom, 4)
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isProcessing {
                progressIndicator
            }
            actionButtons
        }
        .padding(.horizontal, AppStyle.horizontalPadding)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(footerBackground)
    }

    private var footerBackground: some View {
        LinearGradient(
            colors: [
                Color.clear,
                colorScheme == .dark ? .black : .white.opacity(0.8)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Settings Section
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            fileSizePanel
            formatPanel
            if showAdvanced {
                advancedSettings
                    .transition(.scale.combined(with: .opacity))
            }
            advancedToggleButton
        }
        .frame(maxWidth: .infinity)
    }

    private var fileSizePanel: some View {
        settingsCard {
            Text("File Size")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(primary)

            HStack(spacing: 16) {
                Text("Original: \(viewModel.getVideoFileSize())")
                Text("Estimated: \(viewModel.getEstimateExportFileSize())")
            }
            .font(.system(size: 14))
            .foregroundStyle(primary.opacity(0.8))
        }
    }

    private var formatPanel: some View {
        settingsCard {
            Text("Format")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(primary)

            Text("Original: \(originalFormatLabel)")
                .font(.system(size: 14))
                .foregroundStyle(primary.opacity(0.8))

            HStack {
                Text("When Exported:")
                    .font(.system(size: 14))
                    .foregroundStyle(primary.opacity(0.8))

                Picker("", selection: $viewModel.selectedFormat) {
                    Text("mp3").tag(AudioFormat.mp3)
                    Text("wav").tag(AudioFormat.wav)
                    Text("m4a").tag(AudioFormat.m4a)
                }
                .pickerStyle(.menu)
            }
        }
    }

    private var advancedSettings: some View {
        settingsCard {
            HStack {
                Text("Bitrate")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(primary)
                Spacer()
                Text(bitrateLabel)
                    .font(.system(size: 14))
                    .foregroundStyle(primary.opacity(0.8))
                Button(action: { withAnimation { showBitrateInfo.toggle() } }) {
                    Image(systemName: "info.circle")
                        .opacity(0.5)
                }
                .buttonStyle(.plain)
            }

            if showBitrateInfo {
                Text("Bitrate controls audio quality and file size.")
                    .font(.system(size: 13))
                    .foregroundStyle(primary.opacity(0.7))
                    .transition(.opacity)
            }

            if viewModel.selectedFormat == .wav {
                Text("WAV exports keep the original quality (~\(viewModel.getWavBitrateKbps) kbps).")
                    .font(.system(size: 13))
                    .foregroundStyle(primary.opacity(0.7))
                    .transition(.opacity)
            } else {
                Slider(value: $viewModel.bitrate, in: 64...320, step: 1)
                    .tint(accent.color)
            }
        }
    }

    private var advancedToggleButton: some View {
        Button(action: toggleAdvanced) {
            Text(showAdvanced ? "Hide" : "More")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .frame(maxWidth: .infinity)
        }
        .foregroundStyle(accent.color)
        .padding(.vertical, 8)
        .buttonStyle(.plain)
        .animation(.spring(), value: showAdvanced)
    }

    private func settingsCard<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
        AppCard{
            VStack(alignment: .leading, spacing: 8) {
                content()
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Helpers

    private var bitrateLabel: String {
        switch viewModel.selectedFormat {
        case .wav:
            return "~\(String(describing: viewModel.getWavBitrateKbps)) kbps"
        case .mp3, .m4a:
            let clamped = Int(max(min(viewModel.bitrate, 320), 64))
            return "\(clamped) kbps"
        }
    }

    private var previewSection: some View {
        GeometryReader { geometry in
            let spacing: CGFloat = 20
            let arrowWidth: CGFloat = 24
            let availableWidth = geometry.size.width
            let availableForCards = max(availableWidth - spacing - arrowWidth, 0)
            let cardSize = max(min(availableForCards / 2, idealPreviewSize), 0)

            HStack(alignment: .top, spacing: spacing) {
                videoColumn(size: cardSize)
                arrow(height: cardSize, width: arrowWidth)
                audioColumn(size: cardSize)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .task {
                if cardSize > 0, abs(resolvedPreviewSize - cardSize) > 0.5 {
                    resolvedPreviewSize = cardSize
                }
            }
        }
        .frame(height: max(resolvedPreviewSize, 0))
    }

    private func videoColumn(size: CGFloat) -> some View {
        VStack(spacing: 12) {
            VideoPreviewCard(
                url: viewModel.videoURL,
                size: size,
                primaryColor: primary
            )
            Text("Video")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(primary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity)
    }

    private func audioColumn(size: CGFloat) -> some View {
        VStack(spacing: 12) {
            AudioPreviewCard(
                size: size,
                primaryColor: primary,
                accentColor: accent.color,
                audioURL: .constant(nil)
            )
            Text("Audio")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(primary)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(maxWidth: .infinity)
    }

    private func arrow(height: CGFloat, width: CGFloat) -> some View {
        VStack {
            Spacer(minLength: 0)
            Image(systemName: "arrow.right")
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(primary.opacity(0.55))
            Spacer(minLength: 0)
        }
        .frame(width: width, height: height)
    }

    private var exportButton: some View {
        Button(action: convertToAudio) {
            HStack {
                Spacer()
                Text(isProcessing ? "Converting…" : "Convert")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(background)
                Spacer()
            }
            .padding(.vertical, 14)
            .background(accent.color.opacity(isProcessing ? 0.6 : 1))
            .clipShape(Capsule())
            .shadow(color: accent.color.opacity(0.35), radius: 14, x: 0, y: 8)
        }
        .disabled(isProcessing)
        .opacity(isProcessing ? 0.9 : 1)
    }

    private var actionButtons: some View {
        exportButton
            .frame(maxWidth: .infinity)
    }

    private var progressIndicator: some View {
        VStack(alignment: .leading, spacing: 8) {
            ProgressView(value: clampedProgress, total: 1)
                .tint(accent.color)
            Text("\(Int(clampedProgress * 100))% complete")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(primary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func toggleAdvanced() {
        withAnimation(.spring()) {
            showAdvanced.toggle()
        }
        if !showAdvanced {
            showBitrateInfo = false
        }
    }

    private func convertToAudio() {
        guard !isProcessing else { return }
        HapticsManager.shared.pulse()
        progressValue = 0
        isProcessing = true
        activeSheet = nil
        viewModel.convertToAudio()
    }

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite else { return "00:00" }
        let totalSeconds = max(Int(seconds.rounded()), 0)
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }

    private func cancel() {
        HapticsManager.shared.selection()
        dismiss()
    }
    
    private func saveAudioToCache(tempUrl: URL) {
        let durationLabel = formatTime(viewModel.audioDuration)
        do {
            let item = try CacheManager.shared.recordConversion(
                title: viewModel.videoURL.deletingPathExtension().lastPathComponent,
                duration: durationLabel,
                tempURL: tempUrl
            )
            HapticsManager.shared.notify(.success)
            activeSheet = .success(item.fileURL)
        } catch {
            activeSheet = .fail
        }
    }
    
    enum ActiveSheet: Identifiable {
        case success(URL)
        case exporter(URL)
        case fail
        var id: String { String(describing: self) }
    }
}



private struct VideoPreviewCard: View {
    let url: URL
    let size: CGFloat
    let primaryColor: Color

    @Environment(\.colorScheme) private var colorScheme
    @State private var thumbnail: UIImage?
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var timeObserver: Any?
    @State private var endObserver: NSObjectProtocol?
    @State private var hasLoadedMetadata = false
    @State private var showControls = true
    @State private var hideControlsWorkItem: DispatchWorkItem?

    var body: some View {
        ZStack {
            if let player = player, isPlaying {
                PlayerRepresentable(player: player)
                    .scaledToFill()
                    .clipped()
            } else if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                    .fill(primaryColor.opacity(0.08))
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                .stroke(primaryColor.opacity(0.15), lineWidth: 1)
        )
        .overlay(alignment: .bottomLeading) {
            if duration > 0 {
                Text(formatTime(isPlaying ? currentTime : duration))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .padding(11)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.85), radius: 6, x: 0, y: 2)
            }
        }
        .overlay {
            if showControls {
                PlaybackControlIcon(
                    isPlaying: isPlaying,
                    isDisabled: false,
                    backgroundColor: Color.black.opacity(0.65),
                    iconColor: .white
                )
                .padding()
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                .transition(.opacity)
                .animation(.easeInOut, value: showControls)
            }
        }
        .contentShape(RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous))
        .shadow(ShadowConfiguration.mediumConfiguration(for: colorScheme))
        .onTapGesture {
            showControls = true
            resetHideControlsTimer()
            togglePlayback()
        }
        .onAppear(perform: loadMetadata)
        .onDisappear(perform: resetPlayback)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isPlaying ? "Pause preview" : "Play preview")
        .accessibilityAddTraits(.isButton)
    }

    private func togglePlayback() {
        if isPlaying {
            pausePlayback()
            return
        }

        if player == nil {
            player = AVPlayer(url: url)
        }
        addObservers()
        player?.play()
        isPlaying = true
        showControls = true
        resetHideControlsTimer()
    }

    private func resetHideControlsTimer() {
        hideControlsWorkItem?.cancel()
        if isPlaying {
            let workItem = DispatchWorkItem {
                if isPlaying {
                    withAnimation {
                        showControls = false
                    }
                }
            }
            hideControlsWorkItem = workItem
            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: workItem)
        }
    }

    private func pausePlayback() {
        player?.pause()
        isPlaying = false
        showControls = true
        hideControlsWorkItem?.cancel()
    }

    private func resetPlayback() {
        pausePlayback()
        if let player = player, let timeObserver = timeObserver {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        if let endObserver = endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
        currentTime = 0
        player = nil
        hideControlsWorkItem?.cancel()
    }

    private func addObservers() {
        guard let player = player else { return }
        if timeObserver == nil {
            let interval = CMTime(seconds: 0.3, preferredTimescale: 600)
            timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
                currentTime = time.seconds
            }
        }
        if endObserver == nil {
            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: player.currentItem,
                queue: .main
            ) { _ in
                player.pause()
                player.seek(to: .zero)
                currentTime = 0
                isPlaying = false
                showControls = true
                hideControlsWorkItem?.cancel()
            }
        }
    }

    private func loadMetadata() {
        guard !hasLoadedMetadata else { return }
        hasLoadedMetadata = true
        let sourceURL = url
        Task {
            let asset = AVURLAsset(url: sourceURL)
            let durationSeconds = (try? await asset.load(.duration).seconds) ?? 0
            await MainActor.run {
                duration = durationSeconds.isFinite ? max(durationSeconds, 0) : 0
            }

            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            let snapshotTime: CMTime
            if durationSeconds.isFinite, durationSeconds > 0 {
                let midpoint = max(min(durationSeconds / 2, durationSeconds - 0.1), 0)
                snapshotTime = CMTime(seconds: midpoint, preferredTimescale: 600)
            } else {
                snapshotTime = CMTime(seconds: 0, preferredTimescale: 600)
            }
            generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: snapshotTime)]) { _, cgImage, _, result, _ in
                guard result == .succeeded, let cgImage = cgImage else { return }
                let image = UIImage(cgImage: cgImage)
                Task { @MainActor in
                    thumbnail = image
                }
            }
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite else { return "00:00" }
        let totalSeconds = max(Int(seconds.rounded()), 0)
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}

private struct AudioPreviewCard: View {
    let size: CGFloat
    let primaryColor: Color
    let accentColor: Color
    @Binding var audioURL: URL?

    @Environment(\.colorScheme) private var colorScheme
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var endObserver: NSObjectProtocol?
    @State private var timeObserver: Any?
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0

    var body: some View {
        // Precompute values to help the type-checker
        let cornerRadius = AppStyle.cornerRadius
        let iconSize = max(size * 0.4, 1)
        let baseShape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        let baseFill = primaryColor.opacity(0.07)
        let borderStroke = primaryColor.opacity(0.15)
        // let emphasisStroke = primaryColor.opacity(audioURL == nil ? 0 : 0)

        return ZStack {
            // Background layer
            baseShape
                .fill(baseFill)

            // Icon layer
            Image(systemName: "waveform")
                .font(.system(size: iconSize, weight: .regular))
                .foregroundStyle(accentColor.opacity(1))
        }
        .frame(width: size, height: size)
        .clipShape(baseShape)
        .overlay(
            baseShape
                .stroke(borderStroke, lineWidth: 1)
        )
        // Removed emphasis stroke
        .overlay(alignment: .bottomLeading) {
            if duration > 0 {
                Text(formatTime(isPlaying ? currentTime : duration))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .padding(8)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.85), radius: 6, x: 0, y: 2)
            }
        }

        .contentShape(RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous))
        .shadow(ShadowConfiguration.mediumConfiguration(for: colorScheme))
        .onAppear {
            if let url = audioURL {
                loadMetadata(for: url)
            }
        }
        .onChange(of: audioURL) { _, newValue in
            if let url = newValue {
                loadMetadata(for: url)
            } else {
                resetPlayback()
                duration = 0
            }
        }
        .onDisappear {
            resetPlayback()
        }
        .onTapGesture {
            guard audioURL != nil else { return }
            togglePlayback()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(audioURL == nil ? "Audio preview unavailable" : (isPlaying ? "Pause audio preview" : "Play audio preview"))
        .accessibilityAddTraits(.isButton)
        .modifier(AccessibilityHintIfNeeded(shouldShow: audioURL == nil, hint: "Export audio to enable preview"))
    }

    private func togglePlayback() {
        guard let audioURL = audioURL else { return }
        if isPlaying {
            pausePlayback()
            return
        }
        preparePlayer(for: audioURL)
        player?.play()
        isPlaying = true
    }

    private func preparePlayer(for url: URL) {
        if player == nil || (player?.currentItem?.asset as? AVURLAsset)?.url != url {
            removeObservers()
            player = AVPlayer(url: url)
        }
        addObservers()
    }

    private func pausePlayback() {
        player?.pause()
        isPlaying = false
    }

    private func resetPlayback() {
        pausePlayback()
        removeObservers()
        player = nil
        currentTime = 0
    }

    private func removeObservers() {
        if let player = player, let timeObserver = timeObserver {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        if let endObserver = endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
    }

    private func addObservers() {
        guard let player = player else { return }
        if timeObserver == nil {
            let interval = CMTime(seconds: 0.25, preferredTimescale: 600)
            timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
                currentTime = time.seconds
            }
        }
        if endObserver == nil {
            endObserver = NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: player.currentItem,
                queue: .main
            ) { _ in
                player.pause()
                player.seek(to: .zero)
                currentTime = 0
                isPlaying = false
            }
        }
    }

    private func loadMetadata(for url: URL) {
        Task {
            let asset = AVURLAsset(url: url)
            let seconds = (try? await asset.load(.duration).seconds) ?? 0
            await MainActor.run {
                duration = seconds.isFinite && seconds > 0 ? seconds : 0
            }
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite else { return "00:00" }
        let totalSeconds = max(Int(seconds.rounded()), 0)
        let minutes = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}

private struct PlaybackControlIcon: View {
    let isPlaying: Bool
    let isDisabled: Bool
    let backgroundColor: Color
    let iconColor: Color

    var body: some View {
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(iconColor)
                    .shadow(color: .black.opacity(0.85), radius: 6, x: 0, y: 2)
    }
}

private struct PlayerRepresentable: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PlayerView, context: Context) {
        uiView.playerLayer.player = player
    }

    final class PlayerView: UIView {
        override static var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }
}

struct ExportPicker: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        UIDocumentPickerViewController(forExporting: [url])
    }
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
}

private struct AccessibilityHintIfNeeded: ViewModifier {
    let shouldShow: Bool
    let hint: LocalizedStringKey

    func body(content: Content) -> some View {
        if shouldShow {
            content.accessibilityHint(hint)
        } else {
            content
        }
    }
}

 #Preview {
     AudioConversionView(
        viewModel: AudioConversionViewModel(videoConverter: VideoToAudioConverter()),
        videoUrl: URL(fileURLWithPath: "/tmp/test.mov")
     )
         .background(Color.black)
         .preferredColorScheme(.dark)
 }

struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

