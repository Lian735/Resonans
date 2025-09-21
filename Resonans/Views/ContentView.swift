import SwiftUI

struct ContentView: View {
    @State private var videoURL: URL?
    @State private var showPhotoPicker = false
    @State private var showFilePicker = false
    @State private var message: String?
    @State private var showSourceSheet = false
    @State private var showToast = false
    @State private var toastColor: Color = .green
    @State private var showSourceOptions = false
    @State private var showConversionSheet = false
    
    // Recent conversions
    @State private var recents: [RecentItem] = [

    ]
    @State private var showAllRecents = false

    @State private var selectedTab: Int = 0

    @State private var homeScrollTrigger = false
    @State private var toolsScrollTrigger = false
    @State private var settingsScrollTrigger = false
    @State private var showHomeTopBorder = false
    @State private var showToolsTopBorder = false

    private let tools = ToolItem.all
    @State private var selectedTool: ToolItem.Identifier = .audioExtractor


    @AppStorage("accentColor") private var accentRaw = AccentColorOption.purple.rawValue
    private var accent: AccentColorOption { AccentColorOption(rawValue: accentRaw) ?? .purple }

    @Environment(\.colorScheme) private var colorScheme
    private var background: Color { AppStyle.background(for: colorScheme) }
    private var primary: Color { AppStyle.primary(for: colorScheme) }
    private var activeTool: ToolItem? { tools.first { $0.id == selectedTool } }

    var body: some View {
        ZStack(alignment: .topLeading) {
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
                        homeTab.tag(0)
                        toolsTab.tag(1)
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
                                        toolsScrollTrigger.toggle()
                                    } else {
                                        selectedTab = 1
                                        DispatchQueue.main.async {
                                            toolsScrollTrigger.toggle()
                                        }
                                    }
                                }) {
                                    Image(systemName: "wrench.and.screwdriver.fill")
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
            if showSourceOptions {
                HapticsManager.shared.selection()
                withAnimation(.easeInOut(duration: 0.35)) {
                    showSourceOptions = false
                }
            }
        }
        .onChange(of: selectedTab) { _, newValue in
            if showSourceOptions {
                withAnimation(.easeInOut(duration: 0.35)) {
                    showSourceOptions = false
                }
            }
        }
        // Removed unused .confirmationDialog
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
            onDismiss: {
                videoURL = nil
            }
        ) {
            if let url = videoURL {
                ConversionSettingsView(videoURL: url)
            }
        }
    }

    // MARK: - Tabs

    private var homeTab: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    Color.clear
                        .frame(height: AppStyle.innerPadding)
                        .padding(.bottom, -24)
                        .id("top")
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
            .onChange(of: homeScrollTrigger) { _, _ in
                withAnimation {
                    proxy.scrollTo("top", anchor: .top)
                }
            }
        }
    }

    private var toolsTab: some View {
        ToolsView(
            tools: tools,
            selectedTool: $selectedTool,
            scrollToTopTrigger: $toolsScrollTrigger,
            accent: accent,
            primary: primary,
            colorScheme: colorScheme
        ) { tool, isNewSelection in
            let text = isNewSelection ? "\(tool.title) ready." : "\(tool.title) already active."
            presentToast(text, color: accent.color)
        }
        .background(
            GeometryReader { geo -> Color in
                DispatchQueue.main.async {
                    let show = geo.frame(in: .named("toolsScroll")).minY < -24
                    if showToolsTopBorder != show {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showToolsTopBorder = show
                        }
                    }
                }
                return Color.clear
            }
        )
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.gray.opacity(0.5))
                .frame(height: 1)
                .opacity(showToolsTopBorder ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: showToolsTopBorder)
        }
    }

    // MARK: - Subviews

    private var header: some View {
        HStack(alignment: .center) {
            ZStack(alignment: .leading) {
                Text("Resonans")
                    .opacity(selectedTab == 0 ? 1 : 0)
                Text("Tools")
                    .opacity(selectedTab == 1 ? 1 : 0)
                Text("Settings")
                    .opacity(selectedTab == 2 ? 1 : 0)
            }
            .font(.system(size: 46, weight: .heavy, design: .rounded))
            .tracking(0.5)
            .foregroundStyle(primary)
            .padding(.leading, 22)
            .appTextShadow(colorScheme: colorScheme)
            .animation(.easeInOut(duration: 0.25), value: selectedTab)
            Spacer()
            Button(action: {
                HapticsManager.shared.pulse()
                /* TODO: show help */
            }) {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(primary)
                    .appTextShadow(colorScheme: colorScheme)
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
                primarySourceCard(width: fullWidth)
                HStack(spacing: 16) {
                    sourceOptionCard(icon: "doc.fill", title: "Files", width: targetWidth) {
                        showFilePicker = true
                        withAnimation(.easeInOut(duration: 0.35)) {
                            showSourceOptions = false
                        }
                    }
                    sourceOptionCard(icon: "photo.on.rectangle.angled", title: "Photo Library", width: targetWidth) {
                        showPhotoPicker = true
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

    private func primarySourceCard(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(primary.opacity(0.85))
                Text("Active tool")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(primary.opacity(0.75))
                Spacer()
                if let tool = activeTool {
                    Label(tool.title, systemImage: "checkmark.seal.fill")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .labelStyle(.titleAndIcon)
                        .foregroundStyle(accent.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(accent.color.opacity(colorScheme == .dark ? 0.15 : 0.12))
                                .overlay(
                                    Capsule()
                                        .strokeBorder(accent.color.opacity(0.25), lineWidth: 1)
                                )
                        )
                }
            }

            if let tool = activeTool {
                Text(tool.title)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(primary)
                Text(tool.subtitle)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(primary.opacity(0.7))
                    .lineLimit(2)
            } else {
                Text("Choose a tool to get started")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(primary)
            }

            Spacer()

            HStack(spacing: 10) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(primary.opacity(0.6))
                Text("Tap to pick a video")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(primary.opacity(0.6))
            }
        }
        .padding(.horizontal, AppStyle.innerPadding)
        .padding(.vertical, AppStyle.innerPadding)
        .frame(width: width, height: 165)
        .appCardStyle(primary: primary, colorScheme: colorScheme, shadowLevel: .large)
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

    private func sourceOptionCard(icon: String, title: String, width: CGFloat, action: @escaping () -> Void) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(primary)
            Text(title)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(primary)
        }
        .frame(width: width, height: 165)
        .appCardStyle(primary: primary, colorScheme: colorScheme, shadowLevel: .large)
        .onTapGesture {
            HapticsManager.shared.pulse()
            action()
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title inside the box
            Text("Recent conversions")
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardStyle(
            primary: primary,
            colorScheme: colorScheme,
            fillOpacity: AppStyle.subtleCardFillOpacity,
            shadowLevel: .medium
        )
        .padding(.horizontal, AppStyle.horizontalPadding)
        .padding(.bottom, 120)
    }

    // statusMessage is no longer needed; replaced by toast overlay

    // MARK: - Actions

    private func presentToast(_ text: String, color: Color) {
        message = text
        toastColor = color

        if showToast {
            showToast = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                    showToast = true
                }
            }
        } else {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                showToast = true
            }
        }
    }
}

#Preview { ContentView() }
