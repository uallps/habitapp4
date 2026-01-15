import Foundation
import SwiftData

final class SwiftDataContext {
    @MainActor static var shared: ModelContext?
}

@MainActor
final class SwiftDataStorageProvider: StorageProvider {
    private let modelContainer: ModelContainer
    private let context: ModelContext

    init(schema: Schema) {
        // Create container with error handling and recovery
        self.modelContainer = Self.createModelContainer(schema: schema)
        self.context = ModelContext(self.modelContainer)
        SwiftDataContext.shared = self.context
    }
    
    private static func createModelContainer(schema: Schema) -> ModelContainer {
        let fileManager = FileManager.default
        let storeURL: URL
        
        if let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            storeURL = appSupport.appendingPathComponent("default.store")
        } else {
            storeURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("default.store")
        }
        
        // Try to load the existing store
        do {
            let config = ModelConfiguration(url: storeURL)
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            print("Store initialization failed: \(error). Attempting recovery...")
            
            // Delete corrupted files
            do {
                let urls = [
                    storeURL,
                    URL(fileURLWithPath: storeURL.path + "-journal"),
                    URL(fileURLWithPath: storeURL.path + "-wal"),
                    URL(fileURLWithPath: storeURL.path + "-shm")
                ]
                
                for url in urls {
                    if fileManager.fileExists(atPath: url.path) {
                        try fileManager.removeItem(at: url)
                        print("Deleted corrupted store file: \(url.lastPathComponent)")
                    }
                }
            } catch {
                print("Failed to delete corrupted store: \(error)")
            }
            
            // Retry with fresh store
            do {
                let config = ModelConfiguration(url: storeURL)
                return try ModelContainer(for: schema, configurations: config)
            } catch {
                print("Failed to create fresh store, falling back to in-memory: \(error)")
                // Last resort: in-memory only
                let inMemory = ModelConfiguration(isStoredInMemoryOnly: true)
                return try! ModelContainer(for: schema, configurations: inMemory)
            }
        }
    }

    func loadHabits() async throws -> [Habit] {
        try context.fetch(FetchDescriptor<Habit>())
    }

    func saveHabits(habits: [Habit]) async throws {
        let existing = try context.fetch(FetchDescriptor<Habit>())
        let existingIds = Set(existing.map { $0.id })
        let newIds = Set(habits.map { $0.id })

        for item in existing where !newIds.contains(item.id) { context.delete(item) }
        for habit in habits where !existingIds.contains(habit.id) { context.insert(habit) }
        try context.save()
    }
}
