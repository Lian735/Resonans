import SwiftUI

struct AudioExtractorView: View {
    let onClose: () -> Void

    @State private var videoURL: URL?
    @State private var showPhotoPicker = false
    @State private var showFilePicker = false
    @State private var showSourceOptions = false
    @State private var showConversionSheet = false

    @State private var recents: [RecentItem] = []
    @State private var showAllRecents = false

    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("accentColor") private var accentRaw = AccentColorOption.purple.rawValue

    private var accent: AccentColorOption { AccentColorOption(rawValue: accentRaw) ?? .purple }
    private var background: Color { AppStyle.background(for: colorScheme) }
    private var primary: Color { AppStyle.primary(for: colorScheme) }

    init(onClose: @escaping () -> Void = {}) {
        self.onClose = onClose
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    Color.clear
                        .frame(height: AppStyle.innerPadding)
                        .padding(.bottom, -24)
                        .id("top")

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

                        VStack(spacing: 18) {
                            sourceSelectionCard

                            if showSourceOptions {
                                sourceOptionRow
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                    }
                    .padding(.horizontal, AppStyle.horizontalPadding)
                    .frame(maxWidth: .infinity)
                    .frame(height: showSourceOptions ? 230 : 190)

                    recentSection

                    Spacer(minLength: 40)
                }
            }
            .contentShape(Rectangle())
            .onChange(of: showSourceOptions) { _, isPresented in
                if !isPresented {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo("top", anchor: .top)
                    }
                }
            }
        }
        .background(
            .clear
        )
        .sheet(isPresented: $showPhotoPicker) {
            VideoPicker { url in
                videoURL = url
                showConversionSheet = true
            }
        }
        .sheet(isPresented: $showFilePicker) {
            FilePicker { url in
                videoURL = url
                showConversionSheet = true
            }
        }
        .sheet(
            isPresented: $showConversionSheet,
            onDismiss: { videoURL = nil }
        ) {
            if let url = videoURL {
                ConversionSettingsView(videoURL: url)
            }
        }
    }

    private var sourceSelectionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Audio Extractor")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(primary.opacity(0.7))
                    Text("Ready when you are")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(primary)
                }
                Spacer()
                Image(systemName: "waveform")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(accent.color)
            }

            Spacer()

            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppStyle.compactCornerRadius, style: .continuous)
                        .fill(primary.opacity(AppStyle.iconFillOpacity))
                        .frame(width: 84, height: 84)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppStyle.compactCornerRadius, style: .continuous)
                                .stroke(primary.opacity(AppStyle.iconStrokeOpacity), lineWidth: 1)
                        )
                        .appShadow(colorScheme: colorScheme, level: .small, opacity: 0.4)

                    Image(systemName: "plus")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(primary)
                }

                Text("Click to add files")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(primary)

                Text("Choose a video from Files or your photo library.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(primary.opacity(0.65))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)

            Spacer(minLength: 0)
        }
        .padding(AppStyle.innerPadding)
        .frame(maxWidth: .infinity, minHeight: 190)
        .background(
            RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                .fill(primary.opacity(AppStyle.cardFillOpacity))
                .overlay(
                    RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                        .stroke(primary.opacity(AppStyle.strokeOpacity), lineWidth: 1)
                )
        )
        .contentShape(Rectangle())
        .appShadow(colorScheme: colorScheme, level: .large)
        .scaleEffect(showSourceOptions ? 0.92 : 1)
        .animation(.spring(response: 0.45, dampingFraction: 0.7), value: showSourceOptions)
        .onTapGesture {
            HapticsManager.shared.pulse()
            withAnimation(.easeInOut(duration: 0.35)) {
                showSourceOptions.toggle()
            }
        }
    }

    private var sourceOptionRow: some View {
        HStack(spacing: 16) {
            sourceOptionCard(icon: "doc.fill", title: "Import from Files") {
                showFilePicker = true
                showSourceOptions = false
            }

            sourceOptionCard(icon: "photo.on.rectangle", title: "Pick from Photos") {
                showPhotoPicker = true
                showSourceOptions = false
            }
        }
        .transition(.scale(scale: 0.85).combined(with: .opacity))
    }

    private func sourceOptionCard(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticsManager.shared.pulse()
            withAnimation(.easeInOut(duration: 0.3)) {
                action()
            }
        } label: {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundStyle(primary)
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                    .fill(primary.opacity(AppStyle.cardFillOpacity))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                            .stroke(primary.opacity(AppStyle.strokeOpacity), lineWidth: 1)
                    )
            )
            .appShadow(colorScheme: colorScheme, level: .medium)
        }
        .buttonStyle(.plain)
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Recent conversions")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(primary)
                .padding(.top, 16)
                .padding(.horizontal, AppStyle.innerPadding)

            VStack(spacing: 12) {
                if recents.isEmpty {
                    Text("No exports yet")
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .foregroundStyle(primary.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                } else {
                    ForEach(recents.prefix(showAllRecents ? recents.count : 3)) { item in
                        RecentRow(item: item)
                            .padding(.horizontal, 12)
                    }

                    if recents.count > 3 {
                        Button {
                            HapticsManager.shared.pulse()
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showAllRecents.toggle()
                            }
                        } label: {
                            Text(showAllRecents ? "Show less" : "Show more")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(primary.opacity(0.75))
                        }
                        .padding(.top, 6)
                    }
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 18)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                .fill(primary.opacity(AppStyle.subtleCardFillOpacity))
                .overlay(
                    RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                        .stroke(primary.opacity(AppStyle.strokeOpacity), lineWidth: 1)
                )
        )
        .appShadow(colorScheme: colorScheme, level: .medium)
        .padding(.horizontal, AppStyle.horizontalPadding)
    }
}

#Preview {
    AudioExtractorView()
}
