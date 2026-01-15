//
//  Habit.swift
//  HabitApp
//

import Foundation
import SwiftData

@Model
final class Habit: Identifiable, Codable {
    private enum CodingKeys: CodingKey {
        case id, name, detail, frequency, isActive, createdDate, lastCompletedDate
        case iconName, imageData, reminderTime, repeatDays, monthlyDay
    }

    @Attribute(.unique) var id: UUID
    var name: String
    var detail: String
    var frequency: HabitFrequency
    var isActive: Bool
    var createdDate: Date
    var lastCompletedDate: Date?
    var reminderTime: Date?
    var repeatDays: [Int]     // 1=L ... 7=D (solo para weekly)
    var monthlyDay: Int?      // 1...31 (solo para monthly)
    var iconName: String?
    var imageData: Data?

    var description: String {
        get { detail }
        set { detail = newValue }
    }
    
    // Propiedad computada: ¿está completado según su frecuencia?
    var isCompletedForCurrentPeriod: Bool {
        guard let lastCompleted = lastCompletedDate else { return false }
        let calendar = Calendar.current
        let now = Date()
        
        switch frequency {
        case .daily:
            return calendar.isDateInToday(lastCompleted)
        case .weekly:
            return calendar.isDate(lastCompleted, equalTo: now, toGranularity: .weekOfYear)
        case .monthly:
            return calendar.isDate(lastCompleted, equalTo: now, toGranularity: .month)
        case .custom:
            return calendar.isDateInToday(lastCompleted)
        }
    }
    
    // Método para marcar/desmarcar completado
    func toggleCompletion() {
        if isCompletedForCurrentPeriod {
            lastCompletedDate = nil
        } else {
            lastCompletedDate = Date()
        }
    }
    
    init(
        name: String,
        description: String = "",
        frequency: HabitFrequency,
        isActive: Bool = true,
        createdDate: Date = Date()
    ) {
        self.id = UUID()
        self.name = name
        self.detail = description
        self.frequency = frequency
        self.isActive = isActive
        self.createdDate = createdDate
        self.iconName = nil
        self.imageData = nil
        self.reminderTime = nil
        self.repeatDays = []
        self.monthlyDay = nil
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        detail = try container.decode(String.self, forKey: .detail)
        frequency = try container.decode(HabitFrequency.self, forKey: .frequency)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        createdDate = try container.decode(Date.self, forKey: .createdDate)
        lastCompletedDate = try container.decodeIfPresent(Date.self, forKey: .lastCompletedDate)
        iconName = try container.decodeIfPresent(String.self, forKey: .iconName)
        imageData = try container.decodeIfPresent(Data.self, forKey: .imageData)
        reminderTime = try container.decodeIfPresent(Date.self, forKey: .reminderTime)
        repeatDays = try container.decodeIfPresent([Int].self, forKey: .repeatDays) ?? []
        monthlyDay = try container.decodeIfPresent(Int.self, forKey: .monthlyDay)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(detail, forKey: .detail)
        try container.encode(frequency, forKey: .frequency)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(createdDate, forKey: .createdDate)
        try container.encodeIfPresent(lastCompletedDate, forKey: .lastCompletedDate)
        try container.encodeIfPresent(iconName, forKey: .iconName)
        try container.encodeIfPresent(imageData, forKey: .imageData)
        try container.encodeIfPresent(reminderTime, forKey: .reminderTime)
        try container.encode(repeatDays, forKey: .repeatDays)
        try container.encodeIfPresent(monthlyDay, forKey: .monthlyDay)
    }
}

enum HabitFrequency: String, Codable, CaseIterable, Sendable {
    case daily = "Diariamente"
    case weekly = "Semanalmente"
    case monthly = "Mensualmente"
    case custom = "Personalizado"
}

extension HabitFrequency {
    var localizedName: String {
        return self.rawValue
    }
}
