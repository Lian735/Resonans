//
//  Color+Ext.swift
//  Resonans
//
//  Created by Kevin Dallian on 25/10/25.
//

import SwiftUI

extension Color {
    init?(hex: String) {
        var hexString = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard hexString.count == 6,
              let intCode = Int(hexString, radix: 16) else { return nil }
        
        self.init(
            .sRGB,
            red: Double((intCode >> 16) & 0xFF) / 255,
            green: Double((intCode >> 8) & 0xFF) / 255,
            blue: Double(intCode & 0xFF) / 255,
            opacity: 1
        )
    }
}
