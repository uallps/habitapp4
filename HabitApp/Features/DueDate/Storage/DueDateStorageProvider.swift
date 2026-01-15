import Foundation
import SwiftData

@MainActor
protocol DueDateStorageProvider: Sendable {
    func loadTaskDueDate(for taskId: UUID) async throws -> TaskDueDate?
    func saveTaskDueDate(_ taskDueDate: TaskDueDate) async throws
}

@MainActor
final class DueDateSwiftDataStorageProvider: DueDateStorageProvider {
    private let context: ModelContext

    init() {
        guard let context = SwiftDataContext.shared else {
            fatalError("SwiftData context not initialized")
        }
        self.context = context
    }

    func loadTaskDueDate(for taskId: UUID) async throws -> TaskDueDate? {
        let descriptor = FetchDescriptor<TaskDueDate>(predicate: #Predicate { $0.taskUid == taskId })
        let dueDates = try context.fetch(descriptor)
        return dueDates.first
    }

    func saveTaskDueDate(_ dueDate: TaskDueDate) async throws {
        let existing = try await loadTaskDueDate(for: dueDate.taskUid)
        if existing == nil {
            context.insert(dueDate)
        }
        // If exists, it's already modified since it's the same object
        try context.save()
    }
}