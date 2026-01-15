import Foundation

struct HabitStats {
    var completionRate: Double
    var totalCompletions: Int
    var currentStreak: Int
    var lastSevenDays: [Bool]
}