import Foundation
import SwiftData

enum NotesStorage {
    static func deleteNotes(for habitId: UUID) {
        guard let ctx = SwiftDataContext.shared else { return }
        let fetch = FetchDescriptor<HabitNote>(predicate: #Predicate { $0.habitId == habitId })
        if let items = try? ctx.fetch(fetch) {
            items.forEach { ctx.delete($0) }
            try? ctx.save()
        }
    }

    static func loadOrCreateTodayNote(habitId: UUID, today: Date) -> HabitNote? {
        guard let ctx = SwiftDataContext.shared else { return nil }
        let start = Calendar.current.startOfDay(for: today)

        let fetch = FetchDescriptor<HabitNote>(
            predicate: #Predicate { $0.habitId == habitId && $0.date == start }
        )

        if let existing = try? ctx.fetch(fetch).first {
            return existing
        }

        let created = HabitNote(habitId: habitId, date: start)
        ctx.insert(created)
        try? ctx.save()
        return created
    }

    static func saveNote(_ note: HabitNote, text: String) {
        guard let ctx = SwiftDataContext.shared else { return }
        note.text = text
        try? ctx.save()
    }

    static func hasTodayNote(habitId: UUID, today: Date) -> Bool {
        guard let ctx = SwiftDataContext.shared else { return false }
        let start = Calendar.current.startOfDay(for: today)

        let fetch = FetchDescriptor<HabitNote>(
            predicate: #Predicate { note in
                note.habitId == habitId && note.date == start && !note.text.isEmpty
            }
        )
        return (try? ctx.fetch(fetch).first) != nil
    }

    static func fetchRecentNotes(habitId: UUID, today: Date) -> [HabitNote] {
        guard let ctx = SwiftDataContext.shared else { return [] }
        let start = Calendar.current.startOfDay(for: today)
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: start) ?? start

        let fetch = FetchDescriptor<HabitNote>(
            predicate: #Predicate { note in
                note.habitId == habitId &&
                note.date >= sevenDaysAgo &&
                note.date < start &&
                !note.text.isEmpty
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        return (try? ctx.fetch(fetch)) ?? []
    }
}