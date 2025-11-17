//
//  Button.swift
//  Resonans

import SwiftUI

struct GlassButton<Label: View>: View {
    var action: () -> Void
    @ViewBuilder var label: () -> Label
    
    @AppStorage(AppStorageKey.Settings.glassEffectActivated) private var glassEffectActivated: Bool = true
    
    private let disableGlassEffect: Bool
    
    init(disableGlassEffect: Bool = false, action: @escaping () -> Void, label: @escaping () -> Label) {
        self.action = action
        self.label = label
        self.disableGlassEffect = disableGlassEffect
    }
    
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
                .background {
                    Capsule()
                        .glassEffect(.regular.interactive())
                        .tint(Color(.secondaryLabel))
                }
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
