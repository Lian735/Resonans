//
//  EditorDetailView.swift
//  Resonans
//
//  Created by Lian on 11.11.25.
//

import SwiftUI

struct EditorDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Timeline State
    @State private var playheadSeconds: Double = 12 // placeholder current time
    private let totalDurationSeconds: Double = 120  // 2 minutes timeline width

    private struct ScrollOffsetPreferenceKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
    }

    private var currentTimeString: String {
        let total = Int(playheadSeconds.rounded())
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Time Ruler
    private var timeRuler: some View {
        let majorTickEvery: Double = 5
        let pixelsPerSecond: CGFloat = 12 // controls zoom level
        let totalWidth = CGFloat(totalDurationSeconds) * pixelsPerSecond

        return ZStack(alignment: .topLeading) {
            // Baseline
            Rectangle()
                .fill(Color.secondary.opacity(0.25))
                .frame(height: 1)
                .frame(width: totalWidth)
                .offset(y: 20)

            // Ticks and labels
            HStack(spacing: 0) {
                ForEach(0..<(Int(totalDurationSeconds) + 1), id: \.self) { second in
                    let isMajor = second % Int(majorTickEvery) == 0
                    VStack(spacing: 2) {
                        Rectangle()
                            .fill(Color.secondary)
                            .frame(width: 1, height: isMajor ? 18 : 10)
                        if isMajor {
                            Text("\(second)s")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .frame(width: pixelsPerSecond * majorTickEvery, alignment: .leading)
                                .offset(x: 2)
                        } else {
                            Color.clear.frame(width: pixelsPerSecond)
                        }
                    }
                    .frame(width: pixelsPerSecond, alignment: .top)
                }
            }
        }
        .frame(width: totalWidth, height: 40)
    }
    
    // MARK: - Track Row
    private func trackRow(title: String, color: Color) -> some View {
        let pixelsPerSecond: CGFloat = 12
        let totalWidth = CGFloat(totalDurationSeconds) * pixelsPerSecond
        return HStack(alignment: .center, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .trailing)
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(0.15))
                    .frame(height: 28)
                // Example clip blocks
                HStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: 120, height: 22)
                        .overlay(alignment: .leading) { Capsule().fill(.white.opacity(0.3)).frame(width: 3) }
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: 80, height: 22)
                        .overlay(alignment: .leading) { Capsule().fill(.white.opacity(0.3)).frame(width: 3) }
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: 160, height: 22)
                        .overlay(alignment: .leading) { Capsule().fill(.white.opacity(0.3)).frame(width: 3) }
                }
                .padding(.leading, 8)
            }
            .frame(width: totalWidth - 90, alignment: .leading)
        }
        .frame(height: 34)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack {
                    HStack {
                        Image(systemName: "xmark")
                        Spacer()
                        Button("Export") {
                            HapticsManager.shared.pulse()
                        }
                        .buttonStyle(DefaultButtonStyle())
                    }
                    .padding()
                }
                
                VStack {
                    previewSection
                        .frame(height: 350)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                    
                    previewOptions
                        .frame(height: 35)
                    
                    timelineSection
                    
                    Spacer()
                    
                    actionSection
                }
                .padding(.horizontal, 24)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private var previewSection: some View {
        Rectangle()
    }
    
    private var previewOptions: some View {
        HStack {
            HStack(spacing: 16) {
                Button {
                    
                } label: {
                    Image(systemName: "arrowshape.turn.up.left.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Button {
                    
                } label: {
                    Image(systemName: "arrowshape.turn.up.right.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.white)
                }
            }
            Spacer()
            Text(currentTimeString)
                .monospacedDigit()
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.primary)
        }
        .overlay(alignment: .center) {
            Button {
                
            } label: {
                Image(systemName: "pause.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
    }
    
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geo in
                let pixelsPerSecond: CGFloat = 12
                let contentWidth = CGFloat(totalDurationSeconds) * pixelsPerSecond
                let centerX = geo.size.width / 2

                ZStack {
                    // Scrollable timeline content
                    ScrollView(.horizontal, showsIndicators: true) {
                        // Invisible probe view to read scroll offset
                        GeometryReader { proxy in
                            Color.clear
                                .preference(
                                    key: ScrollOffsetPreferenceKey.self,
                                    value: -proxy.frame(in: .named("TimelineScroll")).minX
                                )
                        }
                        .frame(width: 0, height: 0)

                        VStack(alignment: .leading, spacing: 6) {
                            timeRuler
                            trackRow(title: "Main", color: .blue.opacity(0.6))
                            trackRow(title: "Overlay", color: .green.opacity(0.6))
                            trackRow(title: "Audio", color: .orange.opacity(0.8))
                            Spacer()
                        }
                        .frame(width: contentWidth, alignment: .leading)
                        .padding(.horizontal, centerX) // Start/Ende zentrierbar
                    }
                    .coordinateSpace(name: "TimelineScroll")

                    // Centered playhead cursor (immer in der Mitte)
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white)
                        .frame(width: 3)
                        .frame(height: geo.size.height)
                        .position(x: centerX, y: geo.size.height / 2)
                }
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { scrolled in
                    let newTime = Double(scrolled / pixelsPerSecond)
                    playheadSeconds = min(max(newTime, 0), totalDurationSeconds)
                }
            }
        }
    }
    
    private var actionSection: some View {
        EmptyView()
    }
}

#Preview {
    EditorDetailView()
}
