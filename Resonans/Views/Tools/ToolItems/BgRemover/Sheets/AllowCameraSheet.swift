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
    
    init(status: AuthorizationStatus) {
        self.status = status
    }
    
    var body: some View {
        let config = createConfig(status)
        VStack(spacing: 24) {
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .fontWeight(.bold)
                }
                .buttonStyle(.borderless)
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
                        AppCard {
                            HStack {
                                Text(config.buttonTitle)
                                Image(systemName: "chevron.right")
                                    .symbolEffect(
                                        .wiggle,
                                        options: .repeat(.continuous),
                                        value: logoAnimateCheck
                                    )
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
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
        let action: (() -> Void)?
    }
    
    func createConfig(_ status: AuthorizationStatus) -> Config {
        switch status {
        case .notDetermined:
            return Config(
                title: "Allow Camera Access",
                desc: "To capture photos or videos, please allow access to your camera. You’ll be prompted to grant permission on the next screen.",
                buttonTitle: "Allow Access",
                logoColor: .primary,
                action: {
                    Task {
                        let _ = await CameraManager.shared.requestCameraAccess()
                        dismiss()
                    }
                }
            )
            
        case .denied:
            return Config(
                title: "Camera Access Denied",
                desc: "You’ve previously denied camera access. Please enable it in Settings to use this feature.",
                buttonTitle: "Open Settings",
                logoColor: .red.opacity(0.6),
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
                logoColor: .red.opacity(0.6),
                action: {}
            )
            
        default:
            return Config(
                title: "Camera Ready",
                desc: "Your camera is fully authorized. You can dismiss and use the camera",
                buttonTitle: "",
                logoColor: .green.opacity(0.8),
                action: {}
            )
        }
    }
}


#Preview {
    Text("")
        .sheet(isPresented: .constant(true)) {
            AllowCameraSheet(status: .authorized)
        }
}
