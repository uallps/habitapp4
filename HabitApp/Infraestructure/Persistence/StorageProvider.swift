import Foundation

@MainActor
protocol StorageProvider: AnyObject {
    func loadHabits() async throws -> [Habit]
    func saveHabits(habits: [Habit]) async throws
}
