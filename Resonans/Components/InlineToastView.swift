import SwiftUI

struct InlineToastView: View {
    let message: String
    let tint: Color
    let primaryColor: Color
    let iconName: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(primaryColor.opacity(0.9))
                .padding(8)
                .background(primaryColor.opacity(0.12))
                .clipShape(Circle())

            Text(message)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(primaryColor)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: AppStyle.compactCornerRadius, style: .continuous)
                .fill(tint.opacity(0.82))
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppStyle.compactCornerRadius, style: .continuous)
                .stroke(primaryColor.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: tint.opacity(0.4), radius: 18, x: 0, y: 12)
    }
}

#Preview {
    InlineToastView(message: "Clip ready – tap Extract to continue.", tint: .purple, primaryColor: .white, iconName: "checkmark.seal.fill")
        .padding()
        .background(Color.black)
}
