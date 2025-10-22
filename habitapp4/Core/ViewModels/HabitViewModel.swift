//
//  HabitViewModel.swift
//  habitapp4
//
//  Created by Aula03 on 22/10/25.
//
import Foundation
import Combine

class HabitListViewModel: ObservableObject {
    @Published var habits: [Habit] = [
        Habit(title: "Comprar leche", dueDate: Date().addingTimeInterval(86400)),
        Habit(title: "Hacer ejercicio", priority: .high),
        Habit(title: "Llamar a mamá")
    ]
    
    func addHabit(Habit: Habit) {
        habits.append(Habit)
    }
    
    func toggleCompletion(Habit: Habit) {
        if let index = habits.firstIndex(where: { $0.id == Habit.id }) {
            habits[index].isCompleted.toggle()
            habits[index].doneDate = habits[index].isCompleted ? Date() : nil
        }
        //hola
    }
}
