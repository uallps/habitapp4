//
//  HabitListViewModel.swift
//  HabitApp
//

import Foundation
import Combine
import SwiftUI

@MainActor
class HabitListViewModel: ObservableObject {

    private let storageProvider: StorageProvider

    init(storageProvider: StorageProvider) {
        self.storageProvider = storageProvider
    }

    @Published var habits: [Habit] = []

    func loadHabits() async {
        do { habits = try await storageProvider.loadHabits() }
        catch { print("Error loading habits: \(error)") }
    }

    func addHabit(habit: Habit) async {
        habits.append(habit)
        try? await storageProvider.saveHabits(habits: habits)
    }

    func removeHabits(atOffsets offsets: IndexSet) async {
        let habitsToDelete = offsets.map { habits[$0] }

        for habit in habitsToDelete { await PluginRegistry.shared.notifyHabitWillBeDeleted(habit) }

        habits.remove(atOffsets: offsets)
        try? await storageProvider.saveHabits(habits: habits)

        for habit in habitsToDelete { await PluginRegistry.shared.notifyHabitDidDelete(habitId: habit.id) }
    }
    
    func removeHabit(_ habit: Habit) async {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        await removeHabits(atOffsets: IndexSet(integer: index))
    }

    func toggleHabitCompletion(habit: Habit) async {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }

        let wasCompleted = habits[index].isCompletedForCurrentPeriod
        habits[index].lastCompletedDate = wasCompleted ? nil : Date()

        habits = Array(habits)
        try? await storageProvider.saveHabits(habits: habits)

        await PluginRegistry.shared.notifyHabitCompletionDidChange(
            habitId: habits[index].id,
            isCompleted: !wasCompleted,
            completionDate: habits[index].lastCompletedDate
        )
    }

    func saveHabits() async {
        try? await storageProvider.saveHabits(habits: habits)
    }
}
