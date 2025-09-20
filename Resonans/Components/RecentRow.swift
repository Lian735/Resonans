import SwiftUI

struct RecentRow: View {
    let item: RecentItem

    @Environment(\.colorScheme) private var colorScheme
    private var primary: Color { AppColor.primary(for: colorScheme) }

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "waveform")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(primary.opacity(0.9))
                .frame(width: 56, height: 56)
                .appIconBackground(primary: primary, colorScheme: colorScheme, cornerRadius: 14)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(primary)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(item.duration)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(primary.opacity(0.8))
            }
            Spacer()
            Button(action: {
                HapticsManager.shared.pulse()
                /* TODO: share/download */
            }) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(primary)
                    .padding(10)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .appCardBackground(primary: primary, colorScheme: colorScheme, cornerRadius: 22, elevation: .medium)
    }
}

