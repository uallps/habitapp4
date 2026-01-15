import Foundation
import SwiftData

@Model
final class HabitStreak: Identifiable {
    @Attribute(.unique) var id: UUID
    var habitId: UUID
    var currentStreak: Int
    var bestStreak: Int
    var lastCompletedDate: Date?
    var completionDates: [Date]

    init(habitId: UUID) {
        self.id = UUID()
        self.habitId = habitId
        self.currentStreak = 0
        self.bestStreak = 0
        self.lastCompletedDate = nil
        self.completionDates = []
    }
}