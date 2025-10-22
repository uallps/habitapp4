//
//  HabitRowView.swift
//  habitapp4
//
//  Created by Aula03 on 22/10/25.
//
import SwiftUI

struct HabitRowView: View {
    
    let Habit: Habit
    let toggleCompletion : () -> Void
    
    
    var body: some View {
        HStack {
            Button(action: toggleCompletion){
                Image(systemName: Habit.isCompleted ? "checkmark.circle.fill" : "circle")
            }.buttonStyle(.plain)
            VStack(alignment: .leading) {
                Text(Habit.title)
                    .strikethrough(Habit.isCompleted)
                if AppConfig.showDueDates, let dueDate = Habit.dueDate {
                    Text("Vence: \(dueDate.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if AppConfig.showPriorities, let priority = Habit.priority {
                    Text("Prioridad: \(priority.rawValue)")
                        .font(.caption)
                        .foregroundColor(priorityColor(for: priority))
                }
                if Habit.isCompleted, !Habit.doneDateFormatted.isEmpty {
                                   Text("Finalizado en: \(Habit.doneDateFormatted)")
                                       .font(.caption)
                                       .foregroundColor(.secondary)
                               }
            }
        }
    }
    
    private func priorityColor(for priority: Priority) -> Color {
        switch priority {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .red
        }
    }
}
