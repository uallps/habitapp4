//
//  HabitListView.swift
//  habitapp4
//
//  Created by Aula03 on 22/10/25.
//
import Foundation
import SwiftUI

struct HabitListView: View {
    @StateObject var viewModel = HabitListViewModel()

    var body: some View {
        VStack{
            NavigationStack{
                List($viewModel.habits) { $habit in
                    NavigationLink(destination: HabitDetailView(habit: $habit)){
                        HabitRowView(Habit: habit, toggleCompletion: {
                            viewModel.toggleCompletion(Habit:habit)
                        })}
                }
                .toolbar {
                    Button("Añadir Tarea") {
                        let newHabit = Habit(title:"Nueva Habito")
                        viewModel.addHabit(Habit:newHabit)
                    }
                }.navigationTitle("Habito")
            }
        }
    }
}

#Preview {
    HabitListView()
}
