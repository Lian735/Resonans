//
//  Button.swift
//  Resonans

import SwiftUI

struct Button<Label: View>: View {
    var action: () -> Void
    @ViewBuilder var label: () -> Label
    
    @AppStorage("Glass Effect activated") private var glassEffectActivated: Bool = true
    
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
