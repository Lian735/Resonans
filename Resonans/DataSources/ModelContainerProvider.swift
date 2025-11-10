//
//  ModelContainerProvider.swift
//  Resonans
//
//  Created by Kevin Dallian on 10/11/25.
//

import SwiftData
import Foundation

final class ModelContainerProvider {
    let container: ModelContainer
    
    init() {
        do {
            let storeURL = URL.documentsDirectory.appending(path: "coredata.sqlite")
            let config = ModelConfiguration(url: storeURL)
            self.container = try ModelContainer(
                for: History.self,
                configurations: config
            )
        } catch let error {
            fatalError("Error Initializing SwiftData Model Container : \(error)")
        }
    }
}
