import Foundation
import SwiftData

@MainActor
enum ChainedHabitsStorage {

    static func createChain(name: String, habitIds: [UUID]) -> HabitChain? {
        guard let ctx = SwiftDataContext.shared else { return nil }
        let chain = HabitChain(name: name)
        ctx.insert(chain)

        for (idx, hid) in habitIds.enumerated() {
            ctx.insert(HabitChainItem(chainId: chain.id, habitId: hid, position: idx))
        }

        try? ctx.save()
        return chain
    }

    static func fetchChain(chainId: UUID) -> HabitChain? {
        guard let ctx = SwiftDataContext.shared else { return nil }
        let fetch = FetchDescriptor<HabitChain>(predicate: #Predicate { $0.id == chainId })
        return try? ctx.fetch(fetch).first
    }

    static func fetchItems(chainId: UUID) -> [HabitChainItem] {
        guard let ctx = SwiftDataContext.shared else { return [] }
        let fetch = FetchDescriptor<HabitChainItem>(
            predicate: #Predicate { $0.chainId == chainId },
            sortBy: [SortDescriptor(\.position, order: .forward)]
        )
        return (try? ctx.fetch(fetch)) ?? []
    }

    static func fetchChainId(containing habitId: UUID) -> UUID? {
        guard let ctx = SwiftDataContext.shared else { return nil }
        let fetch = FetchDescriptor<HabitChainItem>(predicate: #Predicate { $0.habitId == habitId })
        return try? ctx.fetch(fetch).first?.chainId
    }

    static func fetchHabits(for itemHabitIds: [UUID]) -> [Habit] {
        guard let ctx = SwiftDataContext.shared else { return [] }
        let fetch = FetchDescriptor<Habit>()
        let all = (try? ctx.fetch(fetch)) ?? []
        let set = Set(itemHabitIds)
        return all.filter { set.contains($0.id) }
    }

    static func fetchAllHabits() -> [Habit] {
        guard let ctx = SwiftDataContext.shared else { return [] }
        let fetch = FetchDescriptor<Habit>()
        return (try? ctx.fetch(fetch)) ?? []
    }

    static func deleteChain(chainId: UUID) {
        guard let ctx = SwiftDataContext.shared else { return }

        let items = fetchItems(chainId: chainId)
        items.forEach { ctx.delete($0) }

        if let chain = fetchChain(chainId: chainId) {
            ctx.delete(chain)
        }

        try? ctx.save()
    }

    static func deleteLinks(for habitId: UUID) {
        guard let ctx = SwiftDataContext.shared else { return }

        let fetch = FetchDescriptor<HabitChainItem>(predicate: #Predicate { $0.habitId == habitId })
        let links = (try? ctx.fetch(fetch)) ?? []
        let affectedChainIds = Set(links.map(\.chainId))

        links.forEach { ctx.delete($0) }
        try? ctx.save()

        for chainId in affectedChainIds {
            let remaining = fetchItems(chainId: chainId)
            if remaining.isEmpty {
                deleteChain(chainId: chainId)
            }
        }
    }

    static func replaceItems(chainId: UUID, habitIds: [UUID]) {
        guard let ctx = SwiftDataContext.shared else { return }

        // Borra items actuales
        let existing = fetchItems(chainId: chainId)
        existing.forEach { ctx.delete($0) }

        // Inserta en el orden recibido
        for (idx, hid) in habitIds.enumerated() {
            ctx.insert(HabitChainItem(chainId: chainId, habitId: hid, position: idx))
        }

        try? ctx.save()
    }
}