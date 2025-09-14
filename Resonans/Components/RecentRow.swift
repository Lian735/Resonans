import SwiftUI

struct RecentRow: View {
    let item: RecentItem

    @Environment(\.colorScheme) private var colorScheme
    private var primary: Color { colorScheme == .dark ? .white : .black }

    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(primary.opacity(0.14))
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "waveform")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(primary.opacity(0.9))
                )
                .shadow(color: .black.opacity(0.45), radius: 12, x: 0, y: 6)

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
            Button(action: { /* TODO: share/download */ }) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(primary)
                    .padding(10)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(primary.opacity(0.16))
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(primary.opacity(0.10), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.55), radius: 18, x: 0, y: 10)
        .shadow(color: colorScheme == .dark ? Color.white.opacity(0.06) : Color.white.opacity(0.3), radius: 1, x: 0, y: 1)
    }
}

