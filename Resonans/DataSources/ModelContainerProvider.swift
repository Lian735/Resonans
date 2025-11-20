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

// MARK: - Mocking for SwiftUI Previews
extension ModelContainer {
    static func mock(for type: any PersistentModel.Type) -> ModelContainer {
        let memoryContainer = try! ModelContainer(for: type.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return memoryContainer
    }
}
