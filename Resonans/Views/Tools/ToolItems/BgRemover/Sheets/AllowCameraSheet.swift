//
//  AllowCameraSheet.swift
//  Resonans
//
//  Created by Kevin Dallian on 28/10/25.
//

import SwiftUI

struct AllowCameraSheet: View {
    @Environment(\.dismiss) var dismiss
    @State var logoAnimateCheck: Bool = false
    let status: AuthorizationStatus
    let onStatusChange: (Bool) -> Void
    
    init(status: AuthorizationStatus, onStatusChange: @escaping (Bool) -> Void) {
        self.status = status
        self.onStatusChange = onStatusChange
    }
    
    var body: some View {
        let config = createConfig(status)
        VStack(spacing: 24) {
            HStack {
                Spacer()
                Image(systemName: "xmark")
                    .typography(.custom(size: 24, weight: .bold))
                    .foregroundStyle(.primary)
                    .fontWeight(.bold)
                    .onTapGesture {
                        dismiss()
                    }
            }
            VStack(alignment: .center, spacing: 24) {
                Image(systemName: "camera.viewfinder")
                    .foregroundStyle(config.logoColor)
                    .typography(.custom(size: 72, weight: .bold))
                    .symbolEffect(
                        .bounce,
                        value: logoAnimateCheck
                    )
                VStack(spacing: 10) {
                    Text(config.title)
                        .typography(.displaySmall)
                    Text(config.desc)
                        .multilineTextAlignment(.center)
                        .typography(.body)
                }
                if !config.buttonTitle.isEmpty {
                    Button {
                        config.action?()
                    } label: {
                        HStack {
                            Text(config.buttonTitle)
                                .typography(.bodyBold, color: .white)
                            Image(systemName: config.logoString)
                                .typography(.bodyBold, color: .white)
                                .symbolEffect(
                                    .wiggle,
                                    options: .repeat(.continuous),
                                    value: logoAnimateCheck
                                )
                        }
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(DefaultButtonStyle())
                    .tint(config.logoColor)
                }
            }
        }
        .presentationDetents([.medium])
        .padding(.horizontal, 24)
        .onAppear(perform: startAnimation)
    }
    
    private func startAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            logoAnimateCheck.toggle()
        }
    }
}

extension AllowCameraSheet {
    struct Config {
        let title: String
        let desc: String
        let buttonTitle: String
        let logoColor: Color
        let logoString: String
        let action: (() -> Void)?
    }
    
    func createConfig(_ status: AuthorizationStatus) -> Config {
        switch status {
        case .notDetermined:
            return Config(
                title: "Allow Camera Access",
                desc: "To capture photos or videos, please allow access to your camera. You’ll be prompted to grant permission on the next screen.",
                buttonTitle: "Open Permission",
                logoColor: .accentColor.opacity(0.8),
                logoString: "camera.badge.ellipsis",
                action: {
                    Task {
                        let status = await CameraManager.shared.requestCameraAccess()
                        dismiss()
                        try await Task.sleep(for: .milliseconds(200))
                        onStatusChange(status)
                    }
                }
            )
            
        case .denied:
            return Config(
                title: "Camera Access Denied",
                desc: "You’ve previously denied camera access. Please enable it in Settings to use this feature.",
                buttonTitle: "Open Settings",
                logoColor: .red.opacity(0.8),
                logoString: "gear",
                action: {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            )
            
        case .restricted:
            return Config(
                title: "Camera Access Restricted",
                desc: "Camera access is restricted and cannot be changed due to parental controls or system settings.",
                buttonTitle: "I understand",
                logoColor: .red.opacity(0.8),
                logoString: "arrow.right",
                action: {}
            )
            
        default:
            return Config(
                title: "Camera Ready",
                desc: "Your camera is fully authorized. You can dismiss and use the camera",
                buttonTitle: "",
                logoColor: .green.opacity(0.8),
                logoString: "",
                action: {}
            )
        }
    }
}


#Preview {
    struct Preview: View {
        @State var status: AuthorizationStatus?
        var body: some View {
            VStack {
                Button("Not Determined") { status = .notDetermined }
                Button("Denied") { status = .denied }
                Button("Authorized") { status = .authorized }
                Button("Restricted") { status = .restricted }
            }
            .buttonStyle(DefaultButtonStyle())
            .sheet(item: $status) { status in
                AllowCameraSheet(status: status) { isTrue in
                    print("isTrue: \(isTrue)")
                }
            }
        }
    }
    return Preview()
}
