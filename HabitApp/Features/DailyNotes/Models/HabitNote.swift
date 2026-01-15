import Foundation
import SwiftData

@Model
final class HabitNote: Identifiable {
    @Attribute(.unique) var id: UUID
    var habitId: UUID
    var date: Date
    var text: String

    init(habitId: UUID, date: Date = Date(), text: String = "") {
        self.id = UUID()
        self.habitId = habitId
        self.date = Calendar.current.startOfDay(for: date)
        self.text = text
    }
}