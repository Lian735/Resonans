//
//  ShadowConifg.swift
//  Resonans
//
import SwiftUI

///Configuration for `.shadow(_:)`
///
///Use ``DefaultShadowConfiguration`` for default configurations
///
///- Parameter color: The color for the shadow. Use the color for opacity
///- Parameter radius: The radius for the shadow
///- Parameter offset: The offset for the shadow. Use `width` instead of `x` and `height` instead of `y`
struct ShadowConfiguration: Equatable{
    var color: Color = Color(.sRGBLinear, white: 0, opacity: 0.33)
    
    var radius: CGFloat
    
    var offset: CGSize = .zero
}
