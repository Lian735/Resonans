//
//  ConversionFailSheet.swift
//  Resonans
//
//  Created by Kevin Dallian on 13/10/25.
//

import SwiftUI

struct FailSheet: View {
    let config: Config

    @Environment(\.colorScheme) private var colorScheme

    @State private var animateError = false
    @State private var showHalo = false
    @State private var showXmark = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Spacer()
            illustration
            Spacer()
            actionButtons
        }
        .background(errorBackground)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(false)
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            Text("Conversion Failed")
                .typography(.displayMedium, color: config.primaryColor)

            Spacer()

            Button(action: {
                HapticsManager.shared.selection()
                config.onDone?()
            }) {
                Text("Dismiss")
                    .typography(.titleSmall, color: colorScheme == .dark ? .white: .black)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(config.primaryColor.opacity(0.07))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(config.primaryColor.opacity(0.15), lineWidth: 1)
                    )
            }
        }
        .padding(.top, 18)
        .padding(.bottom, 4)
        .padding(.horizontal, AppStyle.horizontalPadding)
    }

    // MARK: - Illustration
    private var illustration: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.red.opacity(0.25), lineWidth: 12)
                    .scaleEffect(showHalo ? 1.3 : 0.65)
                    .opacity(showHalo ? 0 : 1)
                    .blur(radius: showHalo ? 10 : 0)

                Image(systemName: showXmark ? "xmark.circle.fill" : "circle.fill")
                    .contentTransition(.symbolEffect(.replace))
                    .typography(.custom(size: 96, weight: .bold), color: .red, design: .rounded)
                    .scaleEffect(animateError ? 1 : 0.65)
                    .shadow(color: Color.red.opacity(0.35), radius: 18, x: 0, y: 12)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 150)
            .onAppear(perform: startAnimation)

            Text("Something went wrong while saving.")
                .typography(.titleLarge, color: config.primaryColor)
                .multilineTextAlignment(.center)

            Text("Please try again or check your storage permissions.")
                .typography(.titleSmall, color: .secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.horizontal, AppStyle.horizontalPadding)
    }

    // MARK: - Buttons
    private var actionButtons: some View {
        VStack(spacing: 14) {
            if config.useRetryButton {
                Button(action: handleRetryTapped) {
                    capsuleLabel(
                        title: "Try Again",
                        systemImage: "arrow.clockwise",
                        foreground: colorScheme == .dark ? .black : .white
                    )
                    .background(config.accentColor)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            
            Button {
                config.onDone?()
            } label: {
                capsuleLabel(
                    title: "Cancel",
                    systemImage: "xmark",
                    foreground: config.accentColor
                )
                .background(
                    Capsule()
                        .stroke(config.accentColor.opacity(0.35), lineWidth: 1)
                        .fill(config.accentColor.opacity(0.07))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppStyle.horizontalPadding)
        .shadow(color: config.accentColor.opacity(0.35), radius: 14, x: 0, y: 8)
        .padding(.bottom, 30)
    }

    // MARK: - Background
    private var errorBackground: some View {
        LinearGradient(
            colors: [.red.opacity(0.3), colorScheme == .dark ? .black : .white],
            startPoint: .topLeading,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Helpers
    private func capsuleLabel(title: String, systemImage: String, foreground: Color) -> some View {
        HStack {
            Spacer()
            Label(title, systemImage: systemImage)
                .typography(.titleSmall, color: foreground, design: .rounded)
            Spacer()
        }
        .padding(.vertical, 14)
    }

    private func startAnimation() {
        animateError = false
        showHalo = false
        showXmark = false

        withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) {
            animateError = true
        }

        withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
            showHalo = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
                showXmark = true
            }
        }
    }

    private func handleRetryTapped() {
        HapticsManager.shared.selection()
        config.onRetry?()
    }
}


extension FailSheet {
    struct Config {
        let title: String
        let accentColor: Color
        let primaryColor: Color
        let useRetryButton: Bool
        let onRetry: (() -> Void)?
        let onDone: (() -> Void)?
        
        init(
            title: String,
            accentColor: Color = .accentColor,
            primaryColor: Color = .primary,
            useRetryButton: Bool = true,
            onRetry: (() -> Void)? = nil,
            onDone: (() -> Void)? = nil
        ) {
            self.title = title
            self.accentColor = accentColor
            self.primaryColor = primaryColor
            self.useRetryButton = useRetryButton
            self.onRetry = onRetry
            self.onDone = onDone
        }
    }
}

#Preview {
    FailSheet(
        config: .init(title: "Failed", useRetryButton: true)
    )
}
