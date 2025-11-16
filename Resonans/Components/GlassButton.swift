//
//  Button.swift
//  Resonans

import SwiftUI

/// A SwiftUI button that optionally adopts the system glass style on supported OS versions.
struct GlassButton<Label: View>: View {
    /// Action triggered when the button is tapped.
    var action: () -> Void
    /// Content builder for the button label.
    @ViewBuilder var label: () -> Label
    
    @AppStorage(AppStorageKey.Settings.glassEffectActivated) private var glassEffectActivated: Bool = true
    
    private let disableGlassEffect: Bool
    
    /// Creates a button with a custom label builder.
    init(disableGlassEffect: Bool = false, action: @escaping () -> Void, label: @escaping () -> Label) {
        self.action = action
        self.label = label
        self.disableGlassEffect = disableGlassEffect
    }

    /// Convenience initializer for text-only buttons.
    init(_ title: String, disableGlassEffect: Bool = false, action: @escaping () -> Void) where Label == Text {
        self.action = action
        self.label = { Text(title) }
        self.disableGlassEffect = disableGlassEffect
    }
    
    var body: some View {
        if #available(iOS 26, *){
            if glassEffectActivated && !disableGlassEffect{
                SwiftUI.Button(action: action) {
                    label()
                }
                .buttonStyle(.glassProminent)
            }else{
                SwiftUI.Button(action: action) {
                    label()
                }
            }
        }else{
            SwiftUI.Button(action: action) {
                label()
            }
        }
    }
}

#Preview {
    struct Preview: View {
        var body: some View {
            VStack {
                GlassButton("Hello") {
                    
                }
                SwiftUI.Button("Hello") {
                    
                }
            }
        }
    }
    return Preview()
}
