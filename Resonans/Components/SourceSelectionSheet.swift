import SwiftUI

struct SourceSelectionSheet: View {
    let accentColor: Color
    let primaryColor: Color
    let onImportFromLibrary: () -> Void
    let onImportFromFiles: () -> Void
    let onOpenGallery: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 24) {
            Capsule()
                .fill(primaryColor.opacity(0.15))
                .frame(width: 48, height: 6)
                .padding(.top, 6)

            VStack(spacing: 8) {
                Text("Choose a source")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(primaryColor)

                Text("Import directly from Photos or Files, or jump to the gallery to stage an existing clip.")
                    .font(.system(size: 15))
                    .foregroundStyle(primaryColor.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 12)

            Button(action: onImportFromLibrary) {
                HStack {
                    Image(systemName: "photo.fill")
                    Text("Pick from Photos")
                        .fontWeight(.semibold)
                }
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(accentColor)
                .clipShape(RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous))
            }
            .buttonStyle(.plain)

            HStack(spacing: 14) {
                SourceQuickAction(
                    title: "Files",
                    subtitle: "Browse documents",
                    icon: "folder.fill",
                    accentColor: accentColor,
                    primaryColor: primaryColor,
                    action: onImportFromFiles
                )

                SourceQuickAction(
                    title: "Gallery",
                    subtitle: "Latest clips",
                    icon: "rectangle.stack.fill",
                    accentColor: accentColor,
                    primaryColor: primaryColor,
                    action: onOpenGallery
                )
            }

            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppStyle.cornerRadius, style: .continuous)
                .fill(primaryColor.opacity(colorScheme == .dark ? 0.24 : 0.08))
                .ignoresSafeArea()
        )
        .presentationBackground(.ultraThinMaterial)
    }
}

private struct SourceQuickAction: View {
    let title: String
    let subtitle: String
    let icon: String
    let accentColor: Color
    let primaryColor: Color
    let action: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(accentColor)
                    .frame(width: 36, height: 36)
                    .background(accentColor.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(primaryColor)

                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(primaryColor.opacity(0.6))
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .appCardStyle(
                primary: primaryColor,
                colorScheme: colorScheme,
                cornerRadius: AppStyle.compactCornerRadius,
                fillOpacity: AppStyle.compactCardFillOpacity,
                shadowLevel: .small
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    SourceSelectionSheet(
        accentColor: .purple,
        primaryColor: .white,
        onImportFromLibrary: {},
        onImportFromFiles: {},
        onOpenGallery: {}
    )
    .background(Color.black)
}
