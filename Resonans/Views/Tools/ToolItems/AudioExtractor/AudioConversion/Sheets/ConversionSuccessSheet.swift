//
//  ConversionSuccessSheet.swift
//  Resonans
//
//  Created by Kevin Dallian on 13/10/25.
//

import SwiftUI

struct ConversionSuccessSheet: View {
    let exportURL: URL
    let accentColor: Color
    let primaryColor: Color
    let onSave: () -> Void
    let onDone: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    @State private var animateCheck = false
    @State private var showHalo = false
    @State private var showCheckmark = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Spacer()
            illustration
            Spacer()
            actionButtons
        }
        .background(successBackground)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(false)
    }

    private var header: some View {
        HStack {
            Text("Converted!")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(primaryColor)

            Spacer()

            Button(action: {
                HapticsManager.shared.selection()
                onDone()
            }) {
                Text("Done")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(primaryColor.opacity(0.07))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(primaryColor.opacity(0.15), lineWidth: 1)
                    )
            }
        }
        .padding(.top, 18)
        .padding(.bottom, 4)
        .padding(.horizontal, AppStyle.horizontalPadding)
    }

    private var illustration: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.green.opacity(0.25), lineWidth: 12)
                    .scaleEffect(showHalo ? 1.35 : 0.65)
                    .opacity(showHalo ? 0 : 1)
                    .blur(radius: showHalo ? 10 : 0)

                Image(systemName: showCheckmark ? "checkmark.circle.fill" : "circle.fill")
                    .contentTransition(.symbolEffect(.replace))
                    .font(.system(size: 96, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.green)
                    .scaleEffect(animateCheck ? 1 : 0.65)
                    .shadow(color: Color.green.opacity(0.35), radius: 18, x: 0, y: 12)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 150)
            .onAppear(perform: startAnimation)

            Text("Successfully converted.")
                .font(.system(size: 25, weight: .semibold, design: .rounded))
                .foregroundStyle(primaryColor)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, AppStyle.horizontalPadding)
    }

    private var actionButtons: some View {
        VStack(spacing: 14) {
            Button(action: handleSaveTapped) {
                capsuleLabel(
                    title: "Save to Files",
                    systemImage: "tray.and.arrow.down",
                    foreground: colorScheme == .dark ? .black : .white
                )
                .background(accentColor)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            ShareLink(item: exportURL) {
                capsuleLabel(
                    title: "Share",
                    systemImage: "square.and.arrow.up",
                    foreground: accentColor
                )
                .background(
                    Capsule()
                        .stroke(accentColor.opacity(0.35), lineWidth: 1)
                        .fill(accentColor.opacity(0.07))
                )
            }
            .simultaneousGesture(TapGesture().onEnded { HapticsManager.shared.selection() })
        }
        .padding(.horizontal, AppStyle.horizontalPadding)
        .shadow(color: accentColor.opacity(0.35), radius: 14, x: 0, y: 8)
        .padding(.bottom, 30)
    }

    private var successBackground: some View {
        LinearGradient(
            colors: [.green.opacity(0.3), colorScheme == .dark ? .black : .white],
            startPoint: .topLeading,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private func capsuleLabel(title: String, systemImage: String, foreground: Color) -> some View {
        HStack {
            Spacer()
            Label(title, systemImage: systemImage)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(foreground)
            Spacer()
        }
        .padding(.vertical, 14)
    }

    private func startAnimation() {
        animateCheck = false
        showHalo = false
        showCheckmark = false

        withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) {
            animateCheck = true
        }

        withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
            showHalo = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
                showCheckmark = true
            }
        }
    }

    private func handleSaveTapped() {
        HapticsManager.shared.selection()
        onSave()
    }
}
