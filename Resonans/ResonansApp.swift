//
//  ResonansApp.swift
//  Resonans
//
//  Created by Lian on 07.09.25.
//

import SwiftUI

@main
struct ResonansApp: App {
    @AppStorage("appearance") private var appearanceRaw = Appearance.system.rawValue
    private var appearance: Appearance { Appearance(rawValue: appearanceRaw) ?? .system }
    
    @StateObject private var viewModel = ContentViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .preferredColorScheme(appearance.colorScheme)
                .animation(.easeInOut(duration: 0.4), value: appearanceRaw)
        }
    }
}
