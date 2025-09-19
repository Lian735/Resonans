import SwiftUI
import AVFoundation
import UIKit

struct ConversionSettingsView: View {
    let videoURL: URL
    @Environment(\.dismiss) private var dismiss

    @AppStorage("accentColor") private var accentRaw = AccentColorOption.purple.rawValue
    private var accent: AccentColorOption { AccentColorOption(rawValue: accentRaw) ?? .purple }

    @Environment(\.colorScheme) private var colorScheme
    private var background: Color { colorScheme == .dark ? .black : .white }
    private var primary: Color { colorScheme == .dark ? .white : .black }

    @State private var selectedFormat: AudioFormat = .mp3
    @State private var isProcessing = false
    @State private var progressValue: Double = 0
    @State private var exportURL: URL?
    @State private var showAdvanced = false
    @State private var showSuccessSheet = false
    @State private var audioProperties: AudioProperties?
    @State private var isLoadingAudioProperties = false
    @State private var hasLoadedDefaultBitrate = false
    @State private var userHasAdjustedBitrate = false
    @State private var didCancelConversion = false
    // Example advanced settings state
    @State private var bitrate: Double = 192 // kbps
    @State private var showBitrateInfo = false

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
                Text("Extract audio")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                previewSection

                Spacer(minLength: 20)

                settingsSection

                Spacer(minLength: 12)
            }
            .padding(.horizontal, AppStyle.horizontalPadding)
            .padding(.top, 32)
            .padding(.bottom, 160)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(background.ignoresSafeArea())
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
            .background(background.opacity(0.95).ignoresSafeArea())
        }
        .sheet(isPresented: $showSuccessSheet) {
            if let exportURL = exportURL {
                ConversionSuccessSheet(
                    url: exportURL,
                    accentColor: accent.color,
                    primaryColor: primary,
                    backgroundColor: background,
                    onDone: {
                        showSuccessSheet = false
                        dismiss()
                    }
                )
                .presentationDetents([.fraction(0.55)])
                .presentationDragIndicator(.visible)
            }
        }
        .onAppear(perform: ensureAudioPropertiesLoaded)
    }

    // MARK: - Settings Section
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            // File Size
            ZStack {
                RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                    .fill(primary.opacity(0.09))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                            .strokeBorder(primary.opacity(0.10), lineWidth: 1)
                    )
                VStack(alignment: .leading, spacing: 8) {
                    Text("File Size")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(primary)
                    HStack(spacing: 16) {
                        Text("Original: \(fileSizeString(for: videoURL))")
                            .font(.system(size: 14))
                            .foregroundStyle(primary.opacity(0.8))
                        Text("Estimated: \(estimatedSizeText)")
                            .font(.system(size: 14))
                            .foregroundStyle(primary.opacity(0.8))
                    }
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 18)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Export Format
            ZStack {
                RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                    .fill(primary.opacity(0.09))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                            .strokeBorder(primary.opacity(0.10), lineWidth: 1)
                    )
                VStack(alignment: .leading, spacing: 8) {
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
                .padding(.vertical, 14)
                .padding(.horizontal, 18)
                .frame(maxWidth: .infinity, alignment: .leading)
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
                        ZStack {
                            RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                                .fill(primary.opacity(0.09))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                                        .strokeBorder(primary.opacity(0.10), lineWidth: 1)
                                )
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Bitrate")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundStyle(primary)
                                    Spacer()
                                    Text("\(Int(bitrate)) kbps")
                                        .font(.system(size: 14))
                                        .foregroundStyle(primary.opacity(0.8))
                                    Button(action: {
                                        withAnimation { showBitrateInfo.toggle() }
                                    }) {
                                        Image(systemName: "questionmark.circle")
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
                                Slider(
                                    value: $bitrate,
                                    in: 64...320,
                                    step: 1,
                                    onEditingChanged: { editing in
                                        if editing {
                                            userHasAdjustedBitrate = true
                                        }
                                    }
                                )
                                .tint(accent.color)
                                .disabled(selectedFormat == .wav)
                                .opacity(selectedFormat == .wav ? 0.5 : 1)
                                if selectedFormat == .wav {
                                    Text("WAV exports use lossless quality and ignore bitrate settings.")
                                        .font(.system(size: 13))
                                        .foregroundStyle(primary.opacity(0.65))
                                }
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 18)
                            .frame(maxWidth: .infinity, alignment: .leading)
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

    // MARK: - Helpers
    private func fileSizeString(for url: URL) -> String {
        let resourceValues = try? url.resourceValues(forKeys: [.fileSizeKey])
        if let fileSize = resourceValues?.fileSize {
            return ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
        }
        return "—"
    }

    private var estimatedSizeText: String {
        if isLoadingAudioProperties {
            return "Calculating…"
        }
        guard let bytes = estimatedExportSizeBytes() else { return "—" }
        let clampedBytes = max(bytes, 0)
        return ByteCountFormatter.string(fromByteCount: Int64(clampedBytes.rounded()), countStyle: .file)
    }

    private func estimatedExportSizeBytes() -> Double? {
        if let props = audioProperties {
            let duration = props.duration
            guard duration.isFinite, duration > 0 else { return nil }
            switch selectedFormat {
            case .mp3:
                let bitsPerSecond = Double(max(64, min(320, Int(bitrate)))) * 1000
                return duration * bitsPerSecond / 8
            case .m4a:
                let chosenBitrate = Double(max(64, min(320, Int(bitrate))))
                return duration * chosenBitrate * 1000 / 8
            case .wav:
                let bitsPerChannel = props.bitsPerChannel > 0 ? Double(props.bitsPerChannel) : 16
                let sampleRate = props.sampleRate > 0 ? props.sampleRate : 44_100
                return duration * sampleRate * Double(max(props.channels, 1)) * bitsPerChannel / 8
            }
        } else {
            let asset = AVAsset(url: videoURL)
            let duration = CMTimeGetSeconds(asset.duration)
            guard duration.isFinite, duration > 0 else { return nil }
            let bitsPerSecond = Double(bitrate) * 1000
            return duration * bitsPerSecond / 8
        }
    }

    private func ensureAudioPropertiesLoaded() {
        guard !isLoadingAudioProperties, audioProperties == nil else { return }
        isLoadingAudioProperties = true
        Task {
            let asset = AVURLAsset(url: videoURL)
            do {
                let durationTime = try await asset.load(.duration)
                let duration = durationTime.seconds
                let tracks = try await asset.loadTracks(withMediaType: .audio)

                var sampleRate = 44_100.0
                var channels = 2
                var bitsPerChannel = 16
                var estimatedBitrate: Double?

                if let track = tracks.first {
                    estimatedBitrate = try await track.load(.estimatedDataRate)
                    let descriptions = try await track.load(.formatDescriptions)
                    if let description = descriptions.first,
                       let asbd = CMAudioFormatDescriptionGetStreamBasicDescription(description)?.pointee {
                        if asbd.mSampleRate > 0 { sampleRate = asbd.mSampleRate }
                        if asbd.mChannelsPerFrame > 0 { channels = Int(asbd.mChannelsPerFrame) }
                        if asbd.mBitsPerChannel > 0 { bitsPerChannel = Int(asbd.mBitsPerChannel) }
                    }
                }

                await MainActor.run {
                    audioProperties = AudioProperties(
                        duration: duration.isFinite ? duration : 0,
                        sampleRate: sampleRate,
                        channels: channels,
                        bitsPerChannel: bitsPerChannel,
                        estimatedBitrate: estimatedBitrate
                    )

                    if !userHasAdjustedBitrate,
                       !hasLoadedDefaultBitrate,
                       let estimatedBitrate = estimatedBitrate,
                       estimatedBitrate > 0 {
                        let kbps = min(max(estimatedBitrate / 1000, 64), 320)
                        bitrate = kbps
                    }

                    hasLoadedDefaultBitrate = true
                    isLoadingAudioProperties = false
                }
            } catch {
                await MainActor.run {
                    audioProperties = nil
                    hasLoadedDefaultBitrate = true
                    isLoadingAudioProperties = false
                }
            }
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

    private var actionButtons: some View {
        GeometryReader { geometry in
            let spacing: CGFloat = 12
            let totalWidth = geometry.size.width
            let cancelWidth = max((totalWidth - spacing) * 0.25, 0)
            let exportWidth = max((totalWidth - spacing) * 0.75, 0)

            HStack(spacing: spacing) {
                cancelButton
                    .frame(width: cancelWidth)
                exportButton
                    .frame(width: exportWidth)
            }
            .frame(width: totalWidth, alignment: .center)
        }
        .frame(height: 52)
    }

    private var cancelButton: some View {
        Button(action: cancel) {
            HStack {
                Spacer(minLength: 0)
                Text("Cancel")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(primary)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 14)
            .background(primary.opacity(0.08))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(primary.opacity(0.15), lineWidth: 1)
            )
        }
        .opacity(isProcessing ? 0.85 : 1)
    }

    private var exportButton: some View {
        Button(action: convert) {
            HStack {
                Spacer(minLength: 0)
                Text(isProcessing ? "Exporting…" : "Export")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(background)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 14)
            .background(accent.color.opacity(isProcessing ? 0.6 : 1))
            .clipShape(Capsule())
            .shadow(color: accent.color.opacity(0.35), radius: 14, x: 0, y: 8)
        }
        .disabled(isProcessing)
        .opacity(isProcessing ? 0.9 : 1)
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

    private func cancel() {
        HapticsManager.shared.selection()
        didCancelConversion = true
        isProcessing = false
        showSuccessSheet = false
        exportURL = nil
        dismiss()
    }

    private func convert() {
        guard !isProcessing else { return }
        HapticsManager.shared.pulse()
        exportURL = nil
        progressValue = 0
        isProcessing = true
        didCancelConversion = false
        showSuccessSheet = false
        VideoToAudioConverter.convert(
            videoURL: videoURL,
            format: selectedFormat,
            bitrate: Int(bitrate),
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
                    guard !didCancelConversion else { return }
                    exportURL = url
                    HapticsManager.shared.notify(.success)
                    showSuccessSheet = true
                case .failure:
                    dismiss()
                }
            }
        )
    }
}

private struct AudioProperties {
    let duration: Double
    let sampleRate: Double
    let channels: Int
    let bitsPerChannel: Int
    let estimatedBitrate: Double?
}

private struct VideoPreviewCard: View {
    let url: URL
    let size: CGFloat
    let primaryColor: Color

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
        let asset = AVAsset(url: url)
        let durationSeconds = CMTimeGetSeconds(asset.duration)
        if durationSeconds.isFinite {
            duration = max(durationSeconds, 0)
        }
        DispatchQueue.global(qos: .userInitiated).async {
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            let snapshotTime: CMTime
            if durationSeconds.isFinite, durationSeconds > 0 {
                let midpoint = max(min(durationSeconds / 2, durationSeconds - 0.1), 0)
                snapshotTime = CMTime(seconds: midpoint, preferredTimescale: 600)
            } else {
                snapshotTime = CMTime(seconds: 0, preferredTimescale: 600)
            }
            if let cgImage = try? generator.copyCGImage(at: snapshotTime, actualTime: nil) {
                let image = UIImage(cgImage: cgImage)
                DispatchQueue.main.async {
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
        let asset = AVAsset(url: url)
        let key = "duration"
        if asset.statusOfValue(forKey: key, error: nil) == .loaded {
            updateDuration(with: asset)
        } else {
            asset.loadValuesAsynchronously(forKeys: [key]) {
                updateDuration(with: asset)
            }
        }
    }

    private func updateDuration(with asset: AVAsset) {
        let seconds = CMTimeGetSeconds(asset.duration)
        if seconds.isFinite && seconds > 0 {
            DispatchQueue.main.async {
                duration = seconds
            }
        } else {
            DispatchQueue.main.async {
                duration = 0
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

struct ConversionSuccessSheet: View {
    let url: URL
    let accentColor: Color
    let primaryColor: Color
    let backgroundColor: Color
    let onDone: () -> Void

    @State private var animateCheckmark = false
    @State private var showExporter = false
    @State private var showShareSheet = false

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                Text("Converted!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(primaryColor)
                Spacer()
                Button(action: {
                    HapticsManager.shared.selection()
                    onDone()
                }) {
                    Text("Done")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(accentColor)
            }
            .padding(.top, 4)

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.18))
                        .frame(width: 140, height: 140)
                        .scaleEffect(animateCheckmark ? 1 : 0.6)
                        .opacity(animateCheckmark ? 1 : 0)
                    Circle()
                        .stroke(Color.green.opacity(0.3), lineWidth: 4)
                        .frame(width: 140, height: 140)
                        .scaleEffect(animateCheckmark ? 1.1 : 0.7)
                        .opacity(animateCheckmark ? 1 : 0)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 100, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.green)
                        .scaleEffect(animateCheckmark ? 1 : 0.6)
                        .rotationEffect(.degrees(animateCheckmark ? 0 : -14))
                        .opacity(animateCheckmark ? 1 : 0)
                }
                .frame(height: 150)
                .animation(.spring(response: 0.7, dampingFraction: 0.75, blendDuration: 0.35), value: animateCheckmark)

                Text("Successfully converted")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(primaryColor.opacity(0.9))
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 12) {
                Button(action: {
                    HapticsManager.shared.pulse()
                    showExporter = true
                }) {
                    Label("Save to Files", systemImage: "square.and.arrow.down")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: accentColor.opacity(0.3), radius: 12, x: 0, y: 6)
                }

                Button(action: {
                    HapticsManager.shared.selection()
                    showShareSheet = true
                }) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(primaryColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(primaryColor.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.top, 18)
        .padding(.bottom, 32)
        .frame(maxWidth: .infinity, alignment: .top)
        .background(backgroundColor.opacity(0.98).ignoresSafeArea())
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7, blendDuration: 0.3)) {
                animateCheckmark = true
            }
        }
        .sheet(isPresented: $showExporter) {
            ExportPicker(url: url)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [url])
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        if let popover = controller.popoverPresentationController {
            popover.sourceView = controller.view
            popover.sourceRect = controller.view.bounds
            popover.permittedArrowDirections = []
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
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
