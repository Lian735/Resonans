//
//  AuthorizationStatus.swift
//  Resonans
//
//  Created by Kevin Dallian on 30/10/25.
//

/// Simplified representation of privacy authorization states used by the app.
enum AuthorizationStatus: String, Identifiable {
    case notDetermined
    case restricted
    case denied
    case authorized
    
    /// String identifier to satisfy `Identifiable` conformance for SwiftUI.
    var id: String { String(describing: self) }
}
