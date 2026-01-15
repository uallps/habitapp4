import Testing
import Foundation
@testable import TaskApp


@Suite("Task Model Tests")
struct TaskTests {
    
    @Test("Task initialization with default values")
    func testTaskInitializationWithDefaults() {
        let task = Task(title: "Test Task")
        
        #expect(task.title == "Test Task")
        #expect(task.isCompleted == false)
        #expect(task.priority == nil)
        #expect(task.reminderDate == nil)
    }
    
    @Test("Task initialization with all parameters")
    func testTaskInitializationWithAllParameters() {
        let date = Date()
        let task = Task(
            title: "Complete Task",
            isCompleted: true,
            priority: .high,
            reminderDate: date
        )
        
        #expect(task.title == "Complete Task")
        #expect(task.isCompleted == true)
        #expect(task.priority == .high)
        #expect(task.reminderDate == date)
    }
    
    @Test("Task properties can be modified")
    func testTaskPropertiesModification() {
        var task = Task(title: "Initial Title")
        
        task.title = "Updated Title"
        task.isCompleted = true
        task.priority = .medium
        
        #expect(task.title == "Updated Title")
        #expect(task.isCompleted == true)
        #expect(task.priority == .medium)
    }
    
    @Test("Task encoding and decoding")
    func testTaskCodable() throws {
        let originalTask = Task(
            title: "Codable Task",
            isCompleted: true,
            priority: .low,
            reminderDate: Date()
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalTask)
        
        let decoder = JSONDecoder()
        let decodedTask = try decoder.decode(Task.self, from: data)
        
        #expect(decodedTask.id == originalTask.id)
        #expect(decodedTask.title == originalTask.title)
        #expect(decodedTask.isCompleted == originalTask.isCompleted)
        #expect(decodedTask.priority == originalTask.priority)
    }
    
    @Test("Task with nil optional values encoding")
    func testTaskWithNilValuesEncoding() throws {
        let task = Task(title: "Simple Task")
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(task)
        
        let decoder = JSONDecoder()
        let decodedTask = try decoder.decode(Task.self, from: data)
        
        #expect(decodedTask.priority == nil)
        #expect(decodedTask.reminderDate == nil)
    }
    
    @Test("Priority enum all cases", arguments: [
        Priority.low,
        Priority.medium,
        Priority.high
    ])
    func testPriorityEnumCases(priority: Priority) {
        let task = Task(title: "Test", priority: priority)
        #expect(task.priority == priority)
    }
    
    @Test("Priority enum raw values")
    func testPriorityRawValues() {
        #expect(Priority.low.rawValue == "low")
        #expect(Priority.medium.rawValue == "medium")
        #expect(Priority.high.rawValue == "high")
    }
}
