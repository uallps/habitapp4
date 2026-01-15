import Foundation
import SwiftData

enum StreakStorage {
    static func deleteStreak(for habitId: UUID) {
        guard let ctx = SwiftDataContext.shared else { return }
        let fetch = FetchDescriptor<HabitStreak>(predicate: #Predicate { $0.habitId == habitId })
        if let items = try? ctx.fetch(fetch) {
            items.forEach { ctx.delete($0) }
            try? ctx.save()
        }
    }

    static func loadOrCreateStreak(habitId: UUID) -> HabitStreak? {
        guard let ctx = SwiftDataContext.shared else { return nil }
        let fetch = FetchDescriptor<HabitStreak>(predicate: #Predicate { $0.habitId == habitId })

        if let existing = try? ctx.fetch(fetch).first {
            return existing
        }

        let created = HabitStreak(habitId: habitId)
        ctx.insert(created)
        try? ctx.save()
        return created
    }

    static func applyCompletionChange(habitId: UUID, isCompleted: Bool) {
        guard let ctx = SwiftDataContext.shared else { return }
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        let streak = loadOrCreateStreak(habitId: habitId)
        guard let streak else { return }

        if isCompleted {
            if !streak.completionDates.contains(where: { cal.isDate($0, inSameDayAs: today) }) {
                streak.completionDates.append(today)
            }
            streak.lastCompletedDate = today
        } else {
            streak.completionDates.removeAll { cal.isDate($0, inSameDayAs: today) }
            let sorted = streak.completionDates.map { cal.startOfDay(for: $0) }.sorted(by: >)
            streak.lastCompletedDate = sorted.first
        }

        let set = Set(streak.completionDates.map { cal.startOfDay(for: $0) })
        let start = set.contains(today) ? today : (cal.date(byAdding: .day, value: -1, to: today) ?? today)

        var current = 0
        var cursor = start
        while set.contains(cursor) {
            current += 1
            cursor = cal.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }

        streak.currentStreak = current
        streak.bestStreak = max(streak.bestStreak, current)

        try? ctx.save()
    }

    static func fetchStreak(habitId: UUID) -> HabitStreak? {
        guard let ctx = SwiftDataContext.shared else { return nil }
        let fetch = FetchDescriptor<HabitStreak>(predicate: #Predicate { $0.habitId == habitId })
        return try? ctx.fetch(fetch).first
    }
}