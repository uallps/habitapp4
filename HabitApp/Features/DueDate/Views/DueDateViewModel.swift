import Foundation
import Combine
import SwiftUI

@MainActor
class DueDateViewModel: ObservableObject {    
    private let habitId: UUID
    private let storageProvider: DueDateStorageProvider
    @Published var taskDueDate: TaskDueDate?
    
    init(habitId: UUID, storageProvider: DueDateStorageProvider) {
        self.habitId = habitId
        self.storageProvider = storageProvider
    }
    
    func load() async {
        do {
            if let loadedDueDate = try await storageProvider.loadTaskDueDate(for: habitId) {
                self.taskDueDate = loadedDueDate
            } else {
                taskDueDate = TaskDueDate(taskUid: habitId, dueDate: nil)
                await saveDueDate()
            }
        } catch {
            print("Error loading due date: \(error)")
        }
    }
    
    func saveDueDate() async {
        guard let taskDueDate = taskDueDate else { return }
        do {
            try await storageProvider.saveTaskDueDate(taskDueDate)
        } catch {
            print("Error saving due date: \(error)")
        }
    }
    
    func updateDueDate(_ newDate: Date?) async {
        taskDueDate?.dueDate = newDate
        await saveDueDate()
    }
    
    func removeDueDate() async {
        guard let taskDueDate = taskDueDate else { return }
        taskDueDate.dueDate = nil
        await saveDueDate()
        self.taskDueDate = nil
    }
    
    var formattedDueDate: String {
        guard let dueDate = taskDueDate?.dueDate else {
            return "Sin fecha"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: dueDate)
    }
    
    // MARK: - Propiedades computadas para las vistas
    
    var hasDueDate: Bool {
        taskDueDate?.dueDate != nil
    }
    
    var dueDate: Date? {
        taskDueDate?.dueDate
    }
    
    func toggleDueDate() {
        if hasDueDate {
            _Concurrency.Task {
                await removeDueDate()
            }
        } else {
            taskDueDate?.dueDate = Date()
            _Concurrency.Task {
                await saveDueDate()
            }
        }
    }
    
    func setDueDate(_ date: Date) {
        _Concurrency.Task {
            await updateDueDate(date)
        }
    }
}
