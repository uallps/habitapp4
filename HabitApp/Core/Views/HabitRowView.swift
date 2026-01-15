//
//  HabitRowView.swift
//  HabitApp
//

import SwiftUI

struct HabitRowView: View {
    let habit: Habit
    let onToggle: () async -> Void
    
    @State private var isRefreshing = false
    
    var body: some View {
        HStack {
            // Botón de completado
            Button(action: {
                Task {
                    isRefreshing = true
                    await onToggle()
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 segundos
                    isRefreshing = false
                }
            }) {
                Image(systemName: habit.isCompletedForCurrentPeriod ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(habit.isCompletedForCurrentPeriod ? .green : .gray)
                    .font(.title2)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isRefreshing)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(habit.name)
                    .font(.headline)
                    .strikethrough(habit.isCompletedForCurrentPeriod)
                
                HStack {
                    Label(habit.frequency.rawValue, systemImage: "repeat")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let lastCompleted = habit.lastCompletedDate {
                        Text("Último: \(lastCompleted, style: .relative)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Espacio para plugins (categorías, rachas, etc.)
                HStack {
                    ForEach(0..<PluginRegistry.shared.getHabitRowViews(for: habit).count, id: \.self) { index in
                        PluginRegistry.shared.getHabitRowViews(for: habit)[index]
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .id(habit.lastCompletedDate) // Forzar refresco cuando cambia la fecha
    }
}

#Preview {
    HabitRowView(habit: Habit(name: "Ejercicio", frequency: .daily), onToggle: {})
}