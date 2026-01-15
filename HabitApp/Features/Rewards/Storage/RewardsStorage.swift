import Foundation
import SwiftData

extension Notification.Name {
    static let xpDidChange = Notification.Name("xpDidChange")
}

@MainActor
enum RewardsStorage {

    struct LevelInfo: Equatable {
        let level: Int
        let currentXP: Int
        let nextLevelXP: Int

        var progress: Double {
            guard nextLevelXP > 0 else { return 0 }
            return Double(currentXP) / Double(nextLevelXP)
        }

        var remainingXP: Int { max(0, nextLevelXP - currentXP) }
    }

    static let nextLevelXP: Int = 2000
    static let dailyClaimXP: Int = 50

    static func xp(for habit: Habit) -> Int {
        switch habit.frequency {
        case .daily: return 30
        case .weekly: return 50
        case .monthly: return 70
        case .custom: return 40
        }
    }

    static func levelInfo(totalXP: Int) -> LevelInfo {
        let level = max(1, (totalXP / nextLevelXP) + 1)
        let current = max(0, totalXP % nextLevelXP)
        return LevelInfo(level: level, currentXP: current, nextLevelXP: nextLevelXP)
    }

    static func fetchOrCreateProfile() -> XPProfile? {
        guard let ctx = SwiftDataContext.shared else { return nil }
        let fetch = FetchDescriptor<XPProfile>()
        if let existing = try? ctx.fetch(fetch).first { return existing }

        let created = XPProfile(totalXP: 0, lastDailyClaim: nil)
        ctx.insert(created)
        try? ctx.save()
        return created
    }

    static func addXP(_ delta: Int) {
        guard let ctx = SwiftDataContext.shared else { return }
        guard let profile = fetchOrCreateProfile() else { return }
        profile.totalXP = max(0, profile.totalXP + delta)
        try? ctx.save()
        NotificationCenter.default.post(name: .xpDidChange, object: nil)
    }

    static func canClaimDailyXP(now: Date = Date()) -> Bool {
        guard let profile = fetchOrCreateProfile() else { return false }
        guard let last = profile.lastDailyClaim else { return true }
        return !Calendar.current.isDate(last, inSameDayAs: now)
    }

    @discardableResult
    static func claimDailyXP(now: Date = Date()) -> Bool {
        guard let ctx = SwiftDataContext.shared else { return false }
        guard let profile = fetchOrCreateProfile() else { return false }
        guard canClaimDailyXP(now: now) else { return false }

        profile.lastDailyClaim = now
        profile.totalXP = max(0, profile.totalXP + dailyClaimXP)
        try? ctx.save()
        NotificationCenter.default.post(name: .xpDidChange, object: nil)
        return true
    }

    static func applyHabitCompletionDidChange(habitId: UUID, isCompleted: Bool) {
        guard let ctx = SwiftDataContext.shared else { return }

        let fetch = FetchDescriptor<Habit>(predicate: #Predicate<Habit> { $0.id == habitId })
        guard let habit = try? ctx.fetch(fetch).first else { return }

        let amount = xp(for: habit)
        addXP(isCompleted ? amount : -amount)
    }
}