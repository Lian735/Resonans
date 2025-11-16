//
//  ResonansApp.swift
//  Resonans
//
//  Created by Lian on 07.09.25.
//

import SwiftUI

/// The main entry point for the Resonans app.
///
/// `ResonansApp` initializes the app and manages:
/// - The root ``ContentView`` with ``ContentViewModel``
/// - Appearance preference application (light/dark/system)
/// - Loading favorite tools on launch
///
/// The app automatically applies the user's appearance preference and animates between theme changes.
///
/// - Note: Uses `@AppStorage` to persist appearance preference.
/// - Important: The ``ContentViewModel`` is created as a `@StateObject` and shared throughout the app.
@main
struct ResonansApp: App {
    @AppStorage(AppStorageKey.Settings.appearance) private var appearanceRaw = Appearance.system.rawValue
    private var appearance: Appearance { Appearance(rawValue: appearanceRaw) ?? .system }
    
    @StateObject private var viewModel = ContentViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .onAppear {
                    viewModel.loadFavoritesOnLaunch()
                }
                .preferredColorScheme(appearance.colorScheme)
                .animation(.easeInOut(duration: 0.4), value: appearanceRaw)
        }
    }
}
