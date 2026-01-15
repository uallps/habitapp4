@MainActor
final class MockStorageProvider: StorageProvider {
    private var storedHabits: [Habit] = [
        Habit(name: "Mock Habit 1", frequency: .daily),
        Habit(name: "Mock Habit 2", frequency: .weekly)
    ]
    
    func loadHabits() async throws -> [Habit] {
        return storedHabits
    }
    
    func saveHabits(habits: [Habit]) async throws {
        storedHabits = habits
    }
}
