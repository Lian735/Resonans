import SwiftUI

struct RecentRow: View {
    let item: RecentItem
    let theme: AppTheme
    let onSave: (RecentItem) -> Void

    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(theme.subtleSurface)
                .frame(width: 52, height: 52)
                .overlay(
                    Image(systemName: "waveform")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(theme.foreground)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.foreground)
                    .lineLimit(1)
                Text(item.duration)
                    .font(.footnote)
                    .foregroundStyle(theme.secondary)
            }

            Spacer()

            ShareLink(item: item.fileURL) {
                Image(systemName: "square.and.arrow.up")
                    .foregroundStyle(theme.accentColor)
                    .padding(10)
                    .background(theme.buttonBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .simultaneousGesture(TapGesture().onEnded {
                HapticsManager.shared.selection()
            })

            Button {
                HapticsManager.shared.selection()
                onSave(item)
            } label: {
                Image(systemName: "tray.and.arrow.down")
                    .foregroundStyle(theme.accentColor)
                    .padding(10)
                    .background(theme.buttonBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(theme.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(theme.border, lineWidth: 1)
                )
        )
    }
}

#Preview {
    RecentRow(
        item: RecentItem(title: "Sample clip", duration: "1:20", fileURL: URL(filePath: "/tmp/sample.mp3"), createdAt: Date()),
        theme: AppTheme(accent: .purple, colorScheme: .light),
        onSave: { _ in }
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
