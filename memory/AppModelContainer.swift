import Foundation
import SwiftData

@MainActor
enum AppModelContainer {
    static let shared: ModelContainer = {
        let schema = Schema([
            MemoryDay.self,
            MemoryEvent.self,
            MemoryAttachment.self,
        ])

        let localConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [localConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}
