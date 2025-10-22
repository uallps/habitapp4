//
//  Task.swift
//  habitapp4
//
//  Created by Aula03 on 22/10/25.
//
import Foundation

struct Habit: Identifiable {
    let id = UUID()
    var title: String
    var isCompleted: Bool = false
    var dueDate: Date?
    var priority: Priority?
    var doneDate : Date?

    var doneDateFormatted: String {
            guard let doneDate = doneDate else { return "" }
            let formatter = DateFormatter()
            formatter.dateFormat = "dd-MM-yyyy HH:mm"
            return formatter.string(from: doneDate)
        }
}

enum Priority: String, Codable {
    case low, medium, high
}
