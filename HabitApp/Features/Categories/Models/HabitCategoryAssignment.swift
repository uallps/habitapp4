import Foundation
import SwiftData

@Model
final class HabitCategoryAssignment: Identifiable {
    @Attribute(.unique) var id: UUID
    var habitId: UUID
    var categoryId: UUID

    init(habitId: UUID, categoryId: UUID) {
        self.id = UUID()
        self.habitId = habitId
        self.categoryId = categoryId
    }
}