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
    @State private var showExporter = false

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
                Text("Export Audio")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                previewSection

                exportButton

                if isProcessing {
                    progressIndicator
                }

                Spacer(minLength: 12)
            }
            .padding(.horizontal, AppStyle.horizontalPadding)
            .padding(.top, 32)
            .padding(.bottom, 40)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(background.ignoresSafeArea())
        .sheet(isPresented: $showExporter, onDismiss: { dismiss() }) {
            if let exportURL = exportURL {
                ExportPicker(url: exportURL)
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

            if cardSize > 0, abs(resolvedPreviewSize - cardSize) > 0.5 {
                DispatchQueue.main.async {
                    resolvedPreviewSize = cardSize
                }
            }

            HStack(alignment: .top, spacing: spacing) {
                videoColumn(size: cardSize)
                arrow(height: cardSize, width: arrowWidth)
                audioColumn(size: cardSize)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: max(resolvedPreviewSize, 0))
    }

    private func videoColumn(size: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VideoPreviewCard(
                url: videoURL,
                size: size,
                primaryColor: primary
            )
            Text("File format: \(originalFormatLabel)")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(primary.opacity(0.65))
        }
    }

    private func audioColumn(size: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            AudioPreviewCard(
                size: size,
                primaryColor: primary,
                accentColor: accent.color,
                audioURL: $exportURL
            )
            VStack(alignment: .leading, spacing: 6) {
                Text("Export format")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(primary.opacity(0.8))

                Picker(selection: $selectedFormat) {
                    ForEach(AudioFormat.allCases, id: \.self) { format in
                        Text(format.rawValue)
                            .tag(format)
                    }
                } label: {
                    HStack {
                        Text(selectedFormat.rawValue)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(primary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(primary.opacity(0.6))
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .frame(width: size)
                    .background(
                        RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                            .fill(primary.opacity(0.07))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                                    .strokeBorder(primary.opacity(0.1), lineWidth: 1)
                            )
                    )
                }
                .pickerStyle(.menu)
            }
        }
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
                Text(isProcessing ? "Exporting…" : "Export")
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

    private var progressIndicator: some View {
        VStack(alignment: .leading, spacing: 8) {
            ProgressView(value: clampedProgress, total: 1)
                .tint(accent.color)
            Text("\(Int(clampedProgress * 100))% complete")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(primary.opacity(0.7))
        }
        .frame(maxWidth: resolvedPreviewSize)
    }

    private func convert() {
        guard !isProcessing else { return }
        HapticsManager.shared.pulse()
        exportURL = nil
        progressValue = 0
        isProcessing = true
        VideoToAudioConverter.convert(
            videoURL: videoURL,
            format: selectedFormat,
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
                    exportURL = url
                    showExporter = true
                case .failure:
                    dismiss()
                }
            }
        )
    }
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
        .overlay(
            RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                .stroke(primaryColor, lineWidth: 4)
        )
        .overlay(alignment: .bottomLeading) {
            if duration > 0 {
                Text(formatTime(isPlaying ? currentTime : duration))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .padding(8)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.85), radius: 6, x: 0, y: 2)
            }
        }
        .overlay(alignment: .topLeading) {
            Button(action: togglePlayback) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.85), radius: 6, x: 0, y: 2)
                    .padding(9)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(4)
        }
        .contentShape(RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous))
        .onTapGesture {
            togglePlayback()
        }
        .onAppear(perform: loadMetadata)
        .onDisappear(perform: stopPlayback)
    }

    private func togglePlayback() {
        if isPlaying {
            stopPlayback()
        } else {
            if player == nil {
                player = AVPlayer(url: url)
            }
            addObservers()
            player?.seek(to: .zero)
            player?.play()
            isPlaying = true
        }
    }

    private func stopPlayback() {
        player?.pause()
        if let player = player, let timeObserver = timeObserver {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        if let endObserver = endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
        currentTime = 0
        isPlaying = false
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
                stopPlayback()
                player.seek(to: .zero)
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

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                .fill(primaryColor.opacity(0.07))
            Image(systemName: "waveform")
                .font(.system(size: size * 0.4, weight: .regular))
                .foregroundStyle(accentColor.opacity(0.45))
            Button(action: togglePlayback) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .padding(28)
                    .background(Circle().fill(accentColor))
                    .shadow(color: accentColor.opacity(0.35), radius: 10, x: 0, y: 6)
            }
            .buttonStyle(.plain)
            .disabled(audioURL == nil)
            .opacity(audioURL == nil ? 0.5 : 1)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                .stroke(primaryColor.opacity(0.15), lineWidth: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                .stroke(primaryColor, lineWidth: audioURL == nil ? 0 : 4)
        )
        .onChange(of: audioURL) { _ in
            resetPlayback()
        }
        .onDisappear {
            resetPlayback()
        }
    }

    private func togglePlayback() {
        guard let audioURL = audioURL else { return }
        if isPlaying {
            pause()
            return
        }
        if player == nil || (player?.currentItem?.asset as? AVURLAsset)?.url != audioURL {
            player = AVPlayer(url: audioURL)
        }
        addEndObserver()
        player?.seek(to: .zero)
        player?.play()
        isPlaying = true
    }

    private func pause() {
        player?.pause()
        isPlaying = false
    }

    private func resetPlayback() {
        pause()
        if let endObserver = endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
        player = nil
    }

    private func addEndObserver() {
        guard let player = player, endObserver == nil else { return }
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            pause()
            player.seek(to: .zero)
        }
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

#Preview {
    ConversionSettingsView(videoURL: URL(fileURLWithPath: "/tmp/test.mov"))
        .background(Color.black)
        .preferredColorScheme(.dark)
}
