import SwiftUI

struct RecentRow: View {
    let item: RecentItem
    let onSave: (RecentItem) -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        AppCard{
            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: AppStyle.iconCornerRadius, style: .continuous)
                    .fill(.primary.opacity(AppStyle.iconFillOpacity))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: "waveform")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.primary.opacity(0.9))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppStyle.iconCornerRadius, style: .continuous)
                            .stroke(.primary.opacity(AppStyle.iconStrokeOpacity), lineWidth: 1)
                    )
                    .shadow(ShadowConfiguration.smallConfiguration(for: colorScheme))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text(item.duration)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.primary.opacity(0.8))
                }
                Spacer()
                ShareLink(item: item.fileURL) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.primary.opacity(0.9))
                        .padding(10)
                }
                .simultaneousGesture(TapGesture().onEnded {
                    HapticsManager.shared.selection()
                })
                
                Button(action: {
                    HapticsManager.shared.pulse()
                    onSave(item)
                }) {
                    Image(systemName: "tray.and.arrow.down")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.primary)
                        .padding(10)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

