import Foundation
import SwiftData

enum StatsCalculator {
    static func calculate(for habit: Habit) -> HabitStats {
        let daysSinceCreation = max(1, Calendar.current.dateComponents([.day], from: habit.createdDate, to: Date()).day ?? 1)

        var totalCompletions = 0
        var currentStreak = 0
        var lastSevenDays: [Bool] = Array(repeating: false, count: 7)

        if let ctx = SwiftDataContext.shared {
            let streakFetch = FetchDescriptor<HabitStreak>(
                predicate: #Predicate { $0.habitId == habit.id }
            )
            if let streak = try? ctx.fetch(streakFetch).first {
                totalCompletions = streak.completionDates.count
                currentStreak = streak.currentStreak

                let calendar = Calendar.current
                lastSevenDays = (0..<7).map { dayOffset in
                    let date = calendar.date(byAdding: .day, value: -(6 - dayOffset), to: Date()) ?? Date()
                    let startOfDay = calendar.startOfDay(for: date)
                    return streak.completionDates.contains { calendar.isDate($0, inSameDayAs: startOfDay) }
                }
            }
        }

        var completionRate = Double(totalCompletions) / Double(daysSinceCreation)
        if completionRate > 1.0 { completionRate = 1.0 }

        return HabitStats(
            completionRate: completionRate,
            totalCompletions: totalCompletions,
            currentStreak: currentStreak,
            lastSevenDays: lastSevenDays
        )
    }

    static func loadGlobalStats() -> (totalHabits: Int, activeHabits: Int) {
        guard let ctx = SwiftDataContext.shared else { return (0, 0) }
        let fetch = FetchDescriptor<Habit>()
        if let habits = try? ctx.fetch(fetch) {
            return (habits.count, habits.filter { $0.isActive }.count)
        }
        return (0, 0)
    }
}