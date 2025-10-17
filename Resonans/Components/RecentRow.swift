import SwiftUI

struct RecentRow: View {
    let item: RecentItem
    let onSave: (RecentItem) -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: AppStyle.iconCornerRadius, style: .continuous)
                .fill(.primary.opacity(AppStyle.iconFillOpacity))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: "waveform")
                        .typography(.titleMedium, color: .primary.opacity(0.9))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppStyle.iconCornerRadius, style: .continuous)
                        .stroke(.primary.opacity(AppStyle.iconStrokeOpacity), lineWidth: 1)
                )
                .shadow(ShadowConfiguration.smallConfiguration(for: colorScheme))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .typography(.titleMedium, color: .primary, design: .rounded)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(item.duration)
                    .typography(.caption, color: .primary.opacity(0.8))
            }
            Spacer()
            HStack(spacing: 10) {
                ShareLink(item: item.fileURL) {
                    Image(systemName: "square.and.arrow.up")
                        .typography(.titleMedium, color: .primary.opacity(0.9))
                }
                .simultaneousGesture(TapGesture().onEnded {
                    HapticsManager.shared.selection()
                })
                
                Button(action: {
                    HapticsManager.shared.pulse()
                    onSave(item)
                }) {
                    Image(systemName: "tray.and.arrow.down")
                        .typography(.custom(size: 22, weight: .bold))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

