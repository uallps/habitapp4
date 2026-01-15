import Testing
import Foundation
@testable import HabitApp

@Suite("Habit Model Tests")
struct HabitTests {

    @Test("Habit initialization defaults")
    func testHabitInitializationDefaults() {
        let habit = Habit(name: "Leer", frequency: .daily)

        #expect(habit.name == "Leer")
        #expect(habit.description == "")
        #expect(habit.frequency == .daily)
        #expect(habit.isActive == true)
        #expect(habit.lastCompletedDate == nil)
        #expect(habit.reminderTime == nil)
        #expect(habit.repeatDays.isEmpty)
        #expect(habit.monthlyDay == nil)
        #expect(habit.iconName == nil)
        #expect(habit.imageData == nil)
    }

    @Test("Completion toggles for current period (daily)")
    func testToggleCompletionDaily() {
        let habit = Habit(name: "Agua", frequency: .daily)

        #expect(habit.isCompletedForCurrentPeriod == false)
        habit.toggleCompletion()
        #expect(habit.lastCompletedDate != nil)
        #expect(habit.isCompletedForCurrentPeriod == true)

        habit.toggleCompletion()
        #expect(habit.lastCompletedDate == nil)
        #expect(habit.isCompletedForCurrentPeriod == false)
    }

    @Test("Habit encodes/decodes (Codable)")
    func testHabitCodableRoundTrip() throws {
        let habit = Habit(name: "Gym", description: "Fuerza", frequency: .weekly, isActive: true)
        habit.lastCompletedDate = Date()
        habit.reminderTime = Date().addingTimeInterval(3600)
        habit.repeatDays = [1, 3, 5]
        habit.monthlyDay = 15
        habit.iconName = "flame.fill"

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(habit)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Habit.self, from: data)

        #expect(decoded.id == habit.id)
        #expect(decoded.name == habit.name)
        #expect(decoded.description == habit.description)
        #expect(decoded.frequency == habit.frequency)
        #expect(decoded.isActive == habit.isActive)
        #expect(decoded.repeatDays == habit.repeatDays)
        #expect(decoded.monthlyDay == habit.monthlyDay)
        #expect(decoded.iconName == habit.iconName)
    }
}
