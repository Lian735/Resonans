import SwiftUI
import Photos
import UIKit

struct BottomSheetGallery: View {
    let assets: [PHAsset]
    let onLastItemAppear: () -> Void
    @Binding var selectedAsset: PHAsset?

    private let columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: 16, alignment: .center), count: 3)

    var body: some View {
        let grouped = Dictionary(grouping: assets) { asset in
            asset.creationDate.map { Calendar.current.startOfDay(for: $0) } ?? Date.distantPast
        }
        let sortedDates = grouped.keys.sorted(by: >)
        LazyVStack(alignment: .leading, spacing: 18, pinnedViews: [.sectionHeaders]) {
            ForEach(sortedDates, id: \.self) { date in
                if let items = grouped[date] {
                    Section(header:
                        Text(dateFormatted(date))
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                            .padding(.leading, 6)
                            .padding(.bottom, 4)
                            .shadow(color: .black.opacity(0.9), radius: 4, x: 0, y: -1)
                    ) {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(items, id: \.localIdentifier) { asset in
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
    }

    private func dateFormatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private struct Thumb: View {
        let asset: PHAsset
        let isSelected: Bool
        let tapAction: () -> Void
        @State private var image: UIImage?
        @State private var borderWidth: CGFloat = 2
        @State private var hasAppeared = false

        var body: some View {
            ZStack(alignment: .bottomLeading) {
                Group {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                    }
                }
                Text(formatDuration(asset.duration))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .padding(8)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.85), radius: 6, x: 0, y: 2)
            }
            .frame(width: 100, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(Color.white, lineWidth: isSelected ? borderWidth : 0)
            )
            .contentShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .scaleEffect(hasAppeared ? 1 : 0.8)
            .onTapGesture {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    tapAction()
                }
            }
            .onAppear {
                if image == nil {
                    loadThumbnail()
                }
                if isSelected { animateBorder() }
                if !hasAppeared {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                        hasAppeared = true
                    }
                }
            }
            .onChange(of: isSelected) { newValue in
                if newValue {
                    animateBorder()
                } else {
                    borderWidth = 2
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

        private func animateBorder() {
            borderWidth = 2
            withAnimation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                borderWidth = 6
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

