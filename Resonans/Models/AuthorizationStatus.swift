//
//  AuthorizationStatus.swift
//  Resonans
//
//  Created by Kevin Dallian on 30/10/25.
//

enum AuthorizationStatus: String, Identifiable {
    case notDetermined
    case restricted
    case denied
    case authorized
    
    var id: String { String(describing: self) }
}
