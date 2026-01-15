//
//  DataPlugin.swift
//  TaskApp
//

import Foundation
import SwiftData

protocol DataPlugin: FeaturePlugin {
    var models: [any PersistentModel.Type] { get }

    nonisolated func willDeleteHabit(_ habit: Habit) async
    nonisolated func didDeleteHabit(habitId: UUID) async

    nonisolated func habitCompletionDidChange(
        habitId: UUID,
        isCompleted: Bool,
        completionDate: Date?
    ) async
}

extension DataPlugin {
    nonisolated func willDeleteHabit(_ habit: Habit) async { }
    nonisolated func didDeleteHabit(habitId: UUID) async { }
    nonisolated func habitCompletionDidChange(
        habitId: UUID,
        isCompleted: Bool,
        completionDate: Date?
    ) async { }
}
