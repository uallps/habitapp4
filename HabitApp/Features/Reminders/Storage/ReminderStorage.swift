import Foundation
import SwiftData

@MainActor
enum ReminderStorage {
    static func deleteReminders(for habitId: UUID) {
        guard let ctx = SwiftDataContext.shared else { return }
        let fetch = FetchDescriptor<HabitReminder>(predicate: #Predicate { $0.habitId == habitId })
        if let reminders = try? ctx.fetch(fetch) {
            for reminder in reminders {
                ReminderNotifications.cancel(reminderId: reminder.id, weekdays: reminder.repeatDays)
                ctx.delete(reminder)
            }
            try? ctx.save()
        }
    }

    static func loadOrCreateReminder(habitId: UUID) -> HabitReminder? {
        guard let ctx = SwiftDataContext.shared else { return nil }
        let fetch = FetchDescriptor<HabitReminder>(predicate: #Predicate { $0.habitId == habitId })

        if let existing = try? ctx.fetch(fetch).first {
            return existing
        }

        let created = HabitReminder(habitId: habitId, reminderTime: Date(), isEnabled: false)
        ctx.insert(created)
        try? ctx.save()
        return created
    }

    static func save(_ reminder: HabitReminder) {
        guard let ctx = SwiftDataContext.shared else { return }
        try? ctx.save()
    }

    static func fetchReminders(for habitId: UUID) -> [HabitReminder] {
        guard let ctx = SwiftDataContext.shared else { return [] }
        let fetch = FetchDescriptor<HabitReminder>(
            predicate: #Predicate { $0.habitId == habitId },
            sortBy: [SortDescriptor(\.reminderTime)]
        )
        return (try? ctx.fetch(fetch)) ?? []
    }

    @discardableResult
    static func addReminder(
        habitId: UUID,
        time: Date = Date(),
        isEnabled: Bool = true,
        repeatDays: [Int] = []
    ) -> HabitReminder? {
        guard let ctx = SwiftDataContext.shared else { return nil }
        let created = HabitReminder(
            habitId: habitId,
            reminderTime: time,
            isEnabled: isEnabled,
            repeatDays: repeatDays
        )
        ctx.insert(created)
        try? ctx.save()
        return created
    }

    static func deleteReminder(_ reminder: HabitReminder) {
        guard let ctx = SwiftDataContext.shared else { return }
        ctx.delete(reminder)
        try? ctx.save()
    }
}