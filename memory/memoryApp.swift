//
//  memoryApp.swift
//  memory
//
//  Created by Малова Олеся on 13.04.2026.
//

import SwiftUI
import SwiftData

@main
struct memoryApp: App {
    @MainActor
    private var sharedModelContainer: ModelContainer {
        AppModelContainer.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
    }
}
