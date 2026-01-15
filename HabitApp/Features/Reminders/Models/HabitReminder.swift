import Foundation
import SwiftData

@Model
final class HabitReminder: Identifiable {
    @Attribute(.unique) var id: UUID
    var habitId: UUID
    var reminderTime: Date
    var isEnabled: Bool
    var repeatDays: [Int] // 1=Lunes, 7=Domingo

    init(habitId: UUID, reminderTime: Date = Date(), isEnabled: Bool = true, repeatDays: [Int] = []) {
        self.id = UUID()
        self.habitId = habitId
        self.reminderTime = reminderTime
        self.isEnabled = isEnabled
        self.repeatDays = repeatDays.isEmpty ? [1,2,3,4,5,6,7] : repeatDays
    }
}