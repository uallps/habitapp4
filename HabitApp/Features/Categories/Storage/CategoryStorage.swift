import Foundation
import SwiftData

@MainActor
enum CategoryStorage {
    static func deleteAssignments(for habitId: UUID) {
        guard let ctx = SwiftDataContext.shared else { return }
        let fetch = FetchDescriptor<HabitCategoryAssignment>(predicate: #Predicate { $0.habitId == habitId })
        if let items = try? ctx.fetch(fetch) {
            items.forEach { ctx.delete($0) }
            try? ctx.save()
        }
    }

    static func fetchCategories() -> [HabitCategory] {
        guard let ctx = SwiftDataContext.shared else { return [] }
        let fetch = FetchDescriptor<HabitCategory>(sortBy: [SortDescriptor(\.name)])
        return (try? ctx.fetch(fetch)) ?? []
    }

    static func ensureDefaultCategoriesIfNeeded() {
        guard let ctx = SwiftDataContext.shared else { return }
        let existing = fetchCategories()
        guard existing.isEmpty else { return }

        let defaults = [
            HabitCategory(name: "Salud", colorHex: "#10B981", icon: "heart.fill"),
            HabitCategory(name: "Productividad", colorHex: "#3B82F6", icon: "chart.line.uptrend.xyaxis"),
            HabitCategory(name: "Bienestar", colorHex: "#8B5CF6", icon: "sparkles"),
            HabitCategory(name: "Aprendizaje", colorHex: "#F59E0B", icon: "book.fill")
        ]
        defaults.forEach { ctx.insert($0) }
        try? ctx.save()
    }

    static func fetchAssignmentCategoryId(for habitId: UUID) -> UUID? {
        guard let ctx = SwiftDataContext.shared else { return nil }
        let fetch = FetchDescriptor<HabitCategoryAssignment>(predicate: #Predicate { $0.habitId == habitId })
        return try? ctx.fetch(fetch).first?.categoryId
    }

    static func setAssignment(habitId: UUID, categoryId: UUID?) {
        guard let ctx = SwiftDataContext.shared else { return }

        let fetch = FetchDescriptor<HabitCategoryAssignment>(predicate: #Predicate { $0.habitId == habitId })
        if let existing = try? ctx.fetch(fetch).first { ctx.delete(existing) }

        if let categoryId {
            ctx.insert(HabitCategoryAssignment(habitId: habitId, categoryId: categoryId))
        }

        try? ctx.save()
    }

    static func deleteCategories(_ categories: [HabitCategory], at offsets: IndexSet) {
        guard let ctx = SwiftDataContext.shared else { return }
        for index in offsets { ctx.delete(categories[index]) }
        try? ctx.save()
    }

    static func addCategory(name: String, colorHex: String, icon: String) {
        guard let ctx = SwiftDataContext.shared else { return }
        ctx.insert(HabitCategory(name: name, colorHex: colorHex, icon: icon))
        try? ctx.save()
    }

    static func fetchCategory(for habitId: UUID) -> HabitCategory? {
        guard let ctx = SwiftDataContext.shared else { return nil }
        guard let categoryId = fetchAssignmentCategoryId(for: habitId) else { return nil }
        let fetch = FetchDescriptor<HabitCategory>(predicate: #Predicate { $0.id == categoryId })
        return try? ctx.fetch(fetch).first
    }
}