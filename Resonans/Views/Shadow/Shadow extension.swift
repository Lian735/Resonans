//
//  Shadow extension.swift
//  Resonans
//
import SwiftUI


extension View {
    /// Applies a configurable, non-default shadow.
    /// Uses ``ShadowConfiguration`` (color, radius, offset) instead of the default parameters.
    /// Use ``DefaultShadowConfiguration`` for standard presets.
    /// - Parameter config: The shadow configuration.
    /// - Returns: The view with the shadow applied.
    func shadow(_ config: ShadowConfiguration) -> some View {
        self.shadow(color: config.color, radius: config.radius, x: config.offset.width, y: config.offset.height)
    }
}

