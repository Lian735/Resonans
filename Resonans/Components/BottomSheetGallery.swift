import SwiftUI
import Photos
import UIKit
import AVFoundation

struct BottomSheetGallery: View {
    let assets: [PHAsset]
    let onLastItemAppear: () -> Void
    @Binding var selectedAsset: PHAsset?

    @State private var sections: [AssetSection] = []
    @State private var cachedIdentifiers: [String] = []

    private let columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: 16, alignment: .center), count: 3)
    @Environment(\.colorScheme) private var colorScheme
    private var primary: Color { AppStyle.primary(for: colorScheme) }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    var body: some View {
        let identifiers = assets.map(\.localIdentifier)
        LazyVStack(alignment: .leading, spacing: 18, pinnedViews: [.sectionHeaders]) {
            ForEach(sections) { section in
                Section(header:
                    Text(section.title)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(primary.opacity(0.85))
                            .padding(.leading, 6)
                            .padding(.bottom, 4)
                            .appTextShadow(colorScheme: colorScheme)
                    ) {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(section.assets, id: \.localIdentifier) { asset in
                                let globalIndex = assets.firstIndex(where: { $0.localIdentifier == asset.localIdentifier })
                                Thumb(
                                    asset: asset,
                                    isSelected: selectedAsset?.localIdentifier == asset.localIdentifier,
                                    tapAction: {
                                        if selectedAsset?.localIdentifier == asset.localIdentifier {
                                            selectedAsset = nil
                                        } else {
                                            selectedAsset = asset
                                        }
                                    }
                                )
                                .onAppear {
                                    if let gi = globalIndex, gi == assets.count - 1 {
                                        onLastItemAppear()
                                    }
                                }
                            }
                        }
                        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: assets.count)
                    }
                }
            }
        }
        .onAppear {
            if sections.isEmpty || cachedIdentifiers != identifiers {
                rebuildSections(with: assets, identifiers: identifiers)
            }
        }
        .onChange(of: identifiers) { _, newIdentifiers in
            rebuildSections(with: assets, identifiers: newIdentifiers)
        }
    }

    private func rebuildSections(with assets: [PHAsset], identifiers: [String]) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard !assets.isEmpty else {
                DispatchQueue.main.async {
                    if self.cachedIdentifiers != identifiers {
                        self.cachedIdentifiers = identifiers
                    }
                    self.sections = []
                    Thumb.updatePrefetching(with: [])
                }
                return
            }

            let calendar = Calendar.current
            let grouped = Dictionary(grouping: assets) { asset in
                asset.creationDate.map { calendar.startOfDay(for: $0) } ?? Date.distantPast
            }
            let sortedDates = grouped.keys.sorted(by: >)
            let formatter = BottomSheetGallery.dayFormatter
            let newSections: [AssetSection] = sortedDates.compactMap { date in
                guard let items = grouped[date] else { return nil }
                return AssetSection(id: date, title: formatter.string(from: date), assets: items)
            }
            let prefetchAssets = Array(newSections.flatMap(\.assets).prefix(60))

            DispatchQueue.main.async {
                let currentIdentifiers = self.assets.map(\.localIdentifier)
                guard currentIdentifiers == identifiers else { return }
                self.cachedIdentifiers = identifiers
                self.sections = newSections
                Thumb.updatePrefetching(with: prefetchAssets)
            }
        }
    }

    private struct AssetSection: Identifiable {
        let id: Date
        let title: String
        let assets: [PHAsset]
    }

    private struct Thumb: View {
        let asset: PHAsset
        let isSelected: Bool
        let tapAction: () -> Void
        @State private var image: UIImage?
        @State private var durationText: String = ""
        @State private var hasAppeared = false
        @State private var player: AVPlayer?
        @State private var isPlaying = false
        @State private var currentTime: Double = 0
        @State private var timeObserver: Any?
        @State private var endObserver: NSObjectProtocol?
        @Environment(\.colorScheme) private var colorScheme
        private var primary: Color { colorScheme == .dark ? .white : .black }

        private static let imageManager: PHCachingImageManager = {
            let manager = PHCachingImageManager()
            manager.allowsCachingHighQualityImages = true
            return manager
        }()

        private static let thumbnailTargetSize = CGSize(width: 200, height: 200)

        private final class AssetBox: @unchecked Sendable {
            let asset: AVAsset
            init(asset: AVAsset) {
                self.asset = asset
            }
        }

        var body: some View {
            // Image or placeholder
            ZStack {
                if isSelected, let player = player {
                    PlayerView(player: player)
                        .scaledToFill()
                        .clipped()
                } else {
                    Group {
                        if let image = image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                        } else {
                            RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                                .fill(primary.opacity(0.08))
                        }
                    }
                }
            }
            .frame(width: 100, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous))
            // Border
            .overlay(
                RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                    .strokeBorder(primary.opacity(0.15), lineWidth: 1)
            )
            // Selection highlight
            .overlay(
                RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                    .stroke(primary, lineWidth: isSelected ? 4 : 0)
                    .animation(.easeInOut(duration: 0.25), value: isSelected)
            )
            // Progress or original duration label
            .overlay(alignment: .bottomLeading) {
                if isPlaying {
                    Text(formatDuration(currentTime))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .padding(8)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.85), radius: 6, x: 0, y: 2)
                } else if !durationText.isEmpty {
                    Text(durationText)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .padding(8)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.85), radius: 6, x: 0, y: 2)
                }
            }
            // Play / Pause button
            .overlay(alignment: .topLeading) {
                if isSelected {
                    Button(action: {
                        if isPlaying {
                            player?.pause()
                            isPlaying = false
                        } else {
                            if player == nil {
                                startPreview()
                            } else {
                                player?.play()
                                addTimeObserver()
                                addEndObserver()
                            }
                            isPlaying = true
                        }
                    }) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.85), radius: 6, x: 0, y: 2)
                            .padding(9)
                            .clipShape(Circle())
                            .padding(4)
                    }
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous))
            .appShadow(colorScheme: colorScheme, level: .small, opacity: 0.35)
            .scaleEffect(hasAppeared ? 1 : 0.8)
            .onTapGesture {
                HapticsManager.shared.pulse()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    tapAction()
                }
            }
            .onAppear {
                if image == nil {
                    loadThumbnail()
                }
                if durationText.isEmpty {
                    loadDuration()
                }
                if !hasAppeared {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                        hasAppeared = true
                    }
                }
            }
            .onChange(of: isSelected) { _, newValue in
                if !newValue {
                    stopPreview()
                }
            }
            .onChange(of: asset.localIdentifier) { _, _ in
                if durationText.isEmpty {
                    loadDuration()
                }
            }
            .onDisappear {
                stopPreview()
            }
        }

        static func updatePrefetching(with assets: [PHAsset]) {
            imageManager.stopCachingImagesForAllAssets()
            guard !assets.isEmpty else { return }
            let options = makeImageRequestOptions()
            imageManager.startCachingImages(
                for: assets,
                targetSize: thumbnailTargetSize,
                contentMode: .aspectFill,
                options: options
            )
        }

        private static func makeImageRequestOptions() -> PHImageRequestOptions {
            let options = PHImageRequestOptions()
            options.deliveryMode = .opportunistic
            options.resizeMode = .fast
            options.isNetworkAccessAllowed = true
            return options
        }

        private func loadThumbnail() {
            let options = Thumb.makeImageRequestOptions()
            Thumb.imageManager.requestImage(for: asset,
                                             targetSize: Thumb.thumbnailTargetSize,
                                             contentMode: .aspectFill,
                                             options: options) { result, _ in
                if let result = result {
                    DispatchQueue.main.async {
                        image = result
                    }
                }
            }
        }

        private func loadDuration() {
            // Photos already knows the duration?  Great, use it.
            if asset.duration > 0 {
                durationText = formatDuration(asset.duration)
                return
            }

            // Otherwise we need to query the AVAsset (covers iCloud‑only videos, Live‑Photo movies, etc.).
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, _ in
                guard let avAsset = avAsset else {
                    DispatchQueue.main.async { durationText = "—" }
                    return
                }
                let boxedAsset = AssetBox(asset: avAsset)
                Task {
                    let seconds = (try? await boxedAsset.asset.load(.duration).seconds) ?? 0
                    let formatted = seconds > 0 ? formatDuration(seconds) : "—"
                    await MainActor.run {
                        durationText = formatted
                    }
                }
            }
        }

        private func formatDuration(_ duration: Double) -> String {
            let totalSeconds = Int(duration.rounded())
            let minutes = totalSeconds / 60
            let seconds = totalSeconds % 60
            return String(format: "%02d:%02d", minutes, seconds)
        }

        private func startPreview() {
            currentTime = 0
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            PHImageManager.default().requestPlayerItem(forVideo: asset, options: options) { item, _ in
                DispatchQueue.main.async {
                    guard isSelected, let item = item else { return }
                    let player = AVPlayer(playerItem: item)
                    self.player = player
                    addTimeObserver()
                    addEndObserver()
                    player.play()
                }
            }
        }

        private func stopPreview() {
            if let player = player {
                player.pause()
                if let timeObserver = timeObserver {
                    player.removeTimeObserver(timeObserver)
                    self.timeObserver = nil
                }
                if let endObserver = endObserver {
                    NotificationCenter.default.removeObserver(endObserver)
                    self.endObserver = nil
                }
            }
            currentTime = 0
            isPlaying = false
            player = nil
        }

        private func addTimeObserver() {
            guard let player = player, timeObserver == nil else { return }
            let interval = CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
                currentTime = time.seconds
            }
        }

        private func addEndObserver() {
            guard let player = player, endObserver == nil else { return }
            endObserver = NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
                stopPreview()
            }
        }
    }
}

private struct PlayerView: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> UIView {
        let view = PlayerContainerView()
        view.playerLayer.player = player
        view.playerLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let view = uiView as? PlayerContainerView {
            view.playerLayer.player = player
        }
    }

    private final class PlayerContainerView: UIView {
        override static var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }
}
