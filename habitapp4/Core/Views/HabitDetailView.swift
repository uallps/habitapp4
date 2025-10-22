//
//  HabitDetailView.swift
//  habitapp4
//
//  Created by Aula03 on 22/10/25.
//
import SwiftUI

struct HabitDetailView: View {
    @Binding var habit: Habit;
    
    var body: some View {
        Form {
            TextField("Título del habito", text: $habit.title)
        }
        .navigationTitle($habit.title)
    
    }
}
