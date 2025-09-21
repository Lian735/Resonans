import SwiftUI

struct ResonansTabBar: View {
    @Binding var selectedTab: MainTab
    let accentColor: Color
    let primaryColor: Color
    let onReselect: (MainTab) -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 12) {
            ForEach(MainTab.allCases) { tab in
                Button {
                    HapticsManager.shared.pulse()
                    if selectedTab == tab {
                        onReselect(tab)
                    } else {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedTab = tab
                        }
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: tab.iconName)
                            .font(.system(size: 20, weight: .semibold))
                        Text(tab.shortTitle)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(selectedTab == tab ? Color.white : primaryColor.opacity(0.65))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(
                                selectedTab == tab
                                    ? accentColor
                                    : primaryColor.opacity(AppStyle.compactCardFillOpacity)
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(primaryColor.opacity(AppStyle.cardFillOpacity))
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(primaryColor.opacity(AppStyle.strokeOpacity), lineWidth: 1)
                )
        )
        .appShadow(colorScheme: colorScheme, level: .medium, opacity: 0.35)
    }
}

#Preview {
    ResonansTabBar(
        selectedTab: .constant(.home),
        accentColor: .purple,
        primaryColor: .white,
        onReselect: { _ in }
    )
    .padding()
    .background(Color.black)
}
