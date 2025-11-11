import SwiftUI
import PhotosUI

struct EditorView: View {
    @AppStorage(AppStorageKey.Settings.accentColor) private var accentRaw = AccentColorOption.purple.rawValue
    
    private var accent: AccentColorOption { AccentColorOption(rawValue: accentRaw) ?? .purple }
    
    @State private var openSelectionSheet: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                    .padding(.horizontal, 24)
                
                Divider()
                
                VStack {
                    createProjectBox(icon: "plus.app.fill", title: "Create New Project") {
                                        openSelectionSheet = true
                                    }
                }
                .padding(.horizontal, 24)
            }
            .sheet(isPresented: $openSelectionSheet) {
                MultiAssetPickerSheet(isPresented: $openSelectionSheet, selectionLimit: 0) { assets in
                    // TODO: Handle picked assets (images/videos)
                    print("Picked assets count: \(assets.count)")
                }
            }
        }
        .background(
            LinearGradient(
                colors: [accent.gradient, .clear],
                    startPoint: .topLeading,
                    endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
    
    private var headerSection: some View {
        titleBox {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Editor")
                        .typography(.displaySmall, design: .rounded)
                    Text("Edit your photos and videos")
                        .typography(.titleMedium, color: .primary.opacity(0.7), design: .rounded)
                        .padding(.top, 4)
                }

                Spacer()

                Image(systemName: "scissors")
                    .typography(.custom(size: 35, weight: .medium), color: .primary)
            }
        }
    }
    private func titleBox<Content: View>(@ViewBuilder content: @escaping () -> Content) -> some View {
            VStack(alignment: .leading, spacing: 16) {
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    private func createProjectBox(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticsManager.shared.pulse()
            action()
        } label: {
            AppCard {
                VStack(spacing: 12) {
                    Image(systemName: icon)
                        .typography(.custom(size: 30, weight: .semibold))
                    Text(title)
                        .typography(.titleSmall, design: .rounded)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    EditorView()
}
