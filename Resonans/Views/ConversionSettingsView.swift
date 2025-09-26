import SwiftUI
import AVFoundation
import UIKit

struct ConversionSettingsView: View {
    let videoURL: URL
    @Environment(\.dismiss) private var dismiss

    @AppStorage("accentColor") private var accentRaw = AccentColorOption.purple.rawValue
    private var accent: AccentColorOption { AccentColorOption(rawValue: accentRaw) ?? .purple }

    @Environment(\.colorScheme) private var colorScheme
    private var background: Color { AppStyle.background(for: colorScheme) }
    private var primary: Color { AppStyle.primary(for: colorScheme) }

    @State private var selectedFormat: AudioFormat = .mp3
    @State private var isProcessing = false
    @State private var progressValue: Double = 0
    @State private var exportURL: URL?
    @State private var showExporter = false
    @State private var showSuccessSheet = false
    @State private var showAdvanced = false
    // Example advanced settings state
    @State private var bitrate: Double = 192 // kbps
    @State private var showBitrateInfo = false
    @State private var audioDuration: Double = 0
    @State private var audioSampleRate: Double = 44_100
    @State private var audioChannelCount: Int = 2
    @State private var hasLoadedAudioMetadata = false

    private let idealPreviewSize: CGFloat = 140
    @State private var resolvedPreviewSize: CGFloat = 140

    private var originalFormatLabel: String {
        let ext = videoURL.pathExtension.uppercased()
        return ext.isEmpty ? "UNKNOWN" : ext
    }

    private var clampedProgress: Double {
        min(max(progressValue, 0), 1)
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Title and Done button at the top (like ConversionSuccessSheet)
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
                            .appShadow(colorScheme: colorScheme, level: .small, opacity: 0.3)
                    }
                }
                .padding(.top, 18)
                .padding(.bottom, 4)

                previewSection

                Spacer(minLength: 20)

                settingsSection
            }
            .padding(.horizontal, AppStyle.horizontalPadding)
            .padding(.bottom, 160)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient(
            colors: [accent.gradient, colorScheme == .dark ? .black : .white],
            startPoint: .topLeading,
            endPoint: .bottom
        )
            .ignoresSafeArea()
        )
        .safeAreaInset(edge: .bottom) {
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
            .background(
                LinearGradient(
                    colors: [
                        Color.clear,                  // oben transparent – direkt hinter den Buttons
                        colorScheme == .dark ? .black : .white.opacity(0.8),     // unten dunkler – Screenrand
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(edges: .bottom)
            )
        }
        .sheet(isPresented: $showSuccessSheet) {
            if let exportURL = exportURL {
                ConversionSuccessSheet(
                    exportURL: exportURL,
                    accentColor: accent.color,
                    primaryColor: primary,
                    onSave: { showExporter = true },
                    onDone: {
                        showSuccessSheet = false
                    }
                )
                .presentationBackground(.regularMaterial)
            }
        }
        .sheet(isPresented: $showExporter) {
            if let exportURL = exportURL {
                ExportPicker(url: exportURL)
            }
        }
        .onAppear {
            if !hasLoadedAudioMetadata {
                hasLoadedAudioMetadata = true
                loadAudioProperties()
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(false)
    }

    // MARK: - Settings Section
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            // File Size
            infoPanel {
                Text("File Size")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(primary)
                HStack(spacing: 16) {
                    Text("Original: \(fileSizeString(for: videoURL))")
                        .font(.system(size: 14))
                        .foregroundStyle(primary.opacity(0.8))
                    Text("Estimated: \(estimatedExportSizeString())")
                        .font(.system(size: 14))
                        .foregroundStyle(primary.opacity(0.8))
                }
            }

            // Export Format
            infoPanel {
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
                    Picker("", selection: $selectedFormat) {
                        Text("mp3").tag(AudioFormat.mp3)
                        Text("wav").tag(AudioFormat.wav)
                        Text("m4a").tag(AudioFormat.m4a)
                    }
                    .pickerStyle(.menu)
                }
            }

            // More… button
            if !showAdvanced {
                Button(action: {
                    withAnimation(.spring()) { showAdvanced.toggle() }
                }) {
                    if showAdvanced {
                        Text("Hide")
                            .transition(.opacity)
                    } else {
                        Text("More")
                            .transition(.opacity)
                    }
                }
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(accent.color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .buttonStyle(.plain)
                .animation(.spring(), value: showAdvanced)
            }

            // Advanced settings
            Group {
                if showAdvanced {
                    VStack(spacing: 18) {
                        // Bitrate setting
                        infoPanel {
                            HStack {
                                Text("Bitrate")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundStyle(primary)
                                Spacer()
                                Text(bitrateLabel)
                                    .font(.system(size: 14))
                                    .foregroundStyle(primary.opacity(0.8))
                                Button(action: {
                                    withAnimation { showBitrateInfo.toggle() }
                                }) {
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
                            if selectedFormat == .wav {
                                Text("WAV exports keep the original quality (~\(wavBitrateKbps) kbps).")
                                    .font(.system(size: 13))
                                    .foregroundStyle(primary.opacity(0.7))
                                    .transition(.opacity)
                            } else {
                                Slider(value: $bitrate, in: 64...320, step: 1)
                                    .tint(accent.color)
                            }
                        }
                        // Add more advanced settings here as needed

                        Button(action: {
                            withAnimation(.spring()) { showAdvanced.toggle() }
                        }) {
                            if showAdvanced {
                                Text("Hide")
                                    .transition(.opacity)
                            } else {
                                Text("More")
                                    .transition(.opacity)
                            }
                        }
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(accent.color)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .buttonStyle(.plain)
                        .animation(.spring(), value: showAdvanced)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func infoPanel<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            content()
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardStyle(primary: primary, colorScheme: colorScheme, shadowLevel: .medium)
    }

    // MARK: - Helpers
    private func fileSizeString(for url: URL) -> String {
        let resourceValues = try? url.resourceValues(forKeys: [.fileSizeKey])
        if let fileSize = resourceValues?.fileSize {
            return ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
        }
        return "—"
    }

    private func estimatedExportSizeString() -> String {
        guard audioDuration.isFinite, audioDuration > 0 else { return "—" }
        let bytes: Double
        switch selectedFormat {
        case .wav:
            let channels = max(Double(audioChannelCount), 1)
            let bitDepth = 16.0
            let bitsPerSecond = max(audioSampleRate, 1) * channels * bitDepth
            bytes = audioDuration * bitsPerSecond / 8
        case .mp3, .m4a:
            let clamped = max(min(bitrate, 320), 64)
            bytes = audioDuration * clamped * 1000 / 8
        }
        guard bytes.isFinite, bytes > 0 else { return "—" }
        return ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }

    private var bitrateLabel: String {
        switch selectedFormat {
        case .wav:
            return "~\(wavBitrateKbps) kbps"
        case .mp3, .m4a:
            let clamped = Int(max(min(bitrate, 320), 64))
            return "\(clamped) kbps"
        }
    }

    private var wavBitrateKbps: Int {
        let channels = max(Double(audioChannelCount), 1)
        let bitsPerSecond = max(audioSampleRate, 1) * channels * 16
        return max(Int(bitsPerSecond / 1000), 1)
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
                url: videoURL,
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
                audioURL: $exportURL
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
        Button(action: convert) {
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

    private func convert() {
        guard !isProcessing else { return }
        HapticsManager.shared.pulse()
        exportURL = nil
        progressValue = 0
        isProcessing = true
        showExporter = false
        showSuccessSheet = false
        let targetBitrate = Int(max(min(bitrate, 320), 64))
        VideoToAudioConverter.convert(
            videoURL: videoURL,
            format: selectedFormat,
            bitrate: targetBitrate,
            progress: { value in
                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        progressValue = value
                    }
                }
            },
            completion: { result in
                isProcessing = false
                switch result {
                case .success(let url):
                    let durationLabel = formatTime(audioDuration)
                    do {
                        let item = try CacheManager.shared.recordConversion(
                            title: videoURL.deletingPathExtension().lastPathComponent,
                            duration: durationLabel,
                            tempURL: url
                        )
                        exportURL = item.fileURL
                    } catch {
                        exportURL = url
                    }
                    HapticsManager.shared.notify(.success)
                    showSuccessSheet = true
                case .failure:
                    dismiss()
                }
            }
        )
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

    private func loadAudioProperties() {
        let sourceURL = videoURL
        Task {
            let asset = AVURLAsset(url: sourceURL)
            let durationSeconds: Double
            if let duration = try? await asset.load(.duration) {
                durationSeconds = duration.seconds
            } else {
                durationSeconds = 0
            }

            var sampleRate: Double = 44_100
            var channels: Int = 2

            if let tracks = try? await asset.loadTracks(withMediaType: .audio),
               let track = tracks.first {
                if let formatDescriptions = try? await track.load(.formatDescriptions),
                   let description = formatDescriptions.first,
                   let asbdPtr = CMAudioFormatDescriptionGetStreamBasicDescription(description) {
                    let asbd = asbdPtr.pointee
                    sampleRate = asbd.mSampleRate
                    channels = Int(asbd.mChannelsPerFrame)
                }
            }

            await MainActor.run {
                audioDuration = durationSeconds.isFinite ? max(durationSeconds, 0) : 0
                audioSampleRate = sampleRate
                audioChannelCount = max(channels, 1)
            }
        }
    }
}

private struct ConversionSuccessSheet: View {
    let exportURL: URL
    let accentColor: Color
    let primaryColor: Color
    let onSave: () -> Void
    let onDone: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    @State private var animateCheck = false
    @State private var showHalo = false
    @State private var showExporter = false
    @State private var showCheckmark = false

    var body: some View {
        VStack {
            // Title and Done button at the top
            HStack {
                Text("Converted!")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(primaryColor)
                Spacer()
                Button(action: {
                    HapticsManager.shared.selection()
                    onDone()
                }) {
                    Text("Done")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(primaryColor.opacity(0.07))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(primaryColor.opacity(0.15), lineWidth: 1)
                        )
                }
            }
            .padding(.top, 18)
            .padding(.bottom, 4)
            .padding(.horizontal, AppStyle.horizontalPadding)

            Spacer()

            VStack {
                ZStack {
                    Circle()
                        .stroke(Color.green.opacity(0.25), lineWidth: 12)
                        .scaleEffect(showHalo ? 1.35 : 0.65)
                        .opacity(showHalo ? 0 : 1)
                        .blur(radius: showHalo ? 10 : 0)

                    Image(systemName: showCheckmark ? "checkmark.circle.fill" : "circle.fill")
                        .contentTransition(.symbolEffect(.replace))
                        .font(.system(size: 96, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.green)
                        .scaleEffect(animateCheck ? 1 : 0.65)
                        .shadow(color: Color.green.opacity(0.35), radius: 18, x: 0, y: 12)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 150)
                .onAppear {
                    animateCheck = false
                    showHalo = false
                    showCheckmark = false
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) {
                        animateCheck = true
                    }
                    withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
                        showHalo = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.spring(response: 0.45, dampingFraction: 9)) {
                            showCheckmark = true
                        }
                    }
                }

                Text("Successfully converted.")
                    .font(.system(size: 25, weight: .semibold, design: .rounded))
                    .foregroundStyle(primaryColor)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: 14) {
                Button(action: {
                    HapticsManager.shared.selection()
                    showExporter = true
                }) {
                    HStack {
                        Spacer()
                        Label("Save to Files", systemImage: "tray.and.arrow.down")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(colorScheme == .dark ? .black : .white )
                        Spacer()
                    }
                    .padding(.vertical, 14)
                    .background(accentColor.opacity(1))
                    .clipShape(Capsule())
                }
                .disabled(false)
                .opacity(1)
                .sheet(isPresented: $showExporter) {
                    ExportPicker(url: exportURL)
                }

                ShareLink(item: exportURL) {
                    HStack {
                        Spacer()
                        Label("Share", systemImage: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(accentColor)
                        Spacer()
                    }
                    .padding(.vertical, 14)
                    .background(
                        Capsule()
                            .stroke(accentColor.opacity(0.35), lineWidth: 1)
                            .fill(accentColor.opacity(0.07))
                    )
                }
                .simultaneousGesture(TapGesture().onEnded {
                    HapticsManager.shared.selection()
                })
            }
            .padding(.horizontal, AppStyle.horizontalPadding)
            .shadow(color: accentColor.opacity(0.35), radius: 14, x: 0, y: 8)
            .padding(.bottom, 30)
        }
        .background(LinearGradient(
            colors: [.green.opacity(0.3), colorScheme == .dark ? .black : .white],
            startPoint: .topLeading,
            endPoint: .bottom
        )
            .ignoresSafeArea())
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(false)
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
    @State private var isLoadingThumbnail = true

    var body: some View {
        let cardShape = RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)

        return ZStack {
            cardShape
                .fill(primaryColor.opacity(0.08))

            if let player = player, isPlaying {
                PlayerRepresentable(player: player)
                    .scaledToFill()
                    .clipped()
            } else if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
            }

            if isLoadingThumbnail && !isPlaying && thumbnail == nil {
                ProgressView()
                    .tint(primaryColor.opacity(0.8))
            }
        }
        .frame(width: size, height: size)
        .clipShape(cardShape)
        .overlay(
            cardShape
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
        .appShadow(colorScheme: colorScheme, level: .medium, opacity: 0.35)
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
        if hasLoadedMetadata {
            if thumbnail == nil {
                isLoadingThumbnail = false
            }
            return
        }
        hasLoadedMetadata = true
        isLoadingThumbnail = true
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
                Task { @MainActor in
                    if result == .succeeded, let cgImage = cgImage {
                        let image = UIImage(cgImage: cgImage)
                        thumbnail = image
                    }
                    isLoadingThumbnail = false
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
        .appShadow(colorScheme: colorScheme, level: .medium, opacity: 0.35)
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
     ConversionSettingsView(videoURL: URL(fileURLWithPath: "/tmp/test.mov"))
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

