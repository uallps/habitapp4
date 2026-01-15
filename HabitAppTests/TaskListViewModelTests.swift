import Testing
import Foundation
@testable import TaskApp

// MARK: - Mocks

final class MockStorageProvider: StorageProvider {
    var loadResult: [Task] = []
    var savedSnapshots: [[Task]] = []
    var saveCallCount = 0
    var shouldThrowOnLoad = false
    var shouldThrowOnSave = false
    
    init(loadResult: [Task] = []) {
        self.loadResult = loadResult
    }
    
    func loadTasks() async throws -> [Task] {
        if shouldThrowOnLoad { throw MockError.load }
        return loadResult
    }
    
    func saveTasks(tasks: [Task]) async throws {
        if shouldThrowOnSave { throw MockError.save }
        saveCallCount += 1
        savedSnapshots.append(tasks)
    }
    
    enum MockError: Error { case load, save }
}

// MARK: - Tests

@MainActor
struct TaskListViewModelTests {
    
    @Test
    func testInitialDefaultTasks() async {
        let vm = TaskListViewModel(storageProvider: MockStorageProvider())
        #expect(vm.tasks.count == 3)
        #expect(vm.tasks.map(\.title).contains("Comprar leche"))
    }
    
    @Test
    func testLoadTasksReplacesDefaults() async {
        let loaded = [
            Task(title: "A"),
            Task(title: "B", priority: .high),
            Task(title: "C")
        ]
        let mock = MockStorageProvider(loadResult: loaded)
        let vm = TaskListViewModel(storageProvider: mock)
        await vm.loadTasks()
        #expect(vm.tasks == loaded)
    }
    
    @Test
    func testLoadTasksErrorDoesNotCrash() async {
        let mock = MockStorageProvider()
        mock.shouldThrowOnLoad = true
        let vm = TaskListViewModel(storageProvider: mock)
        await vm.loadTasks()
        // Fallback: tasks remain default
        #expect(vm.tasks.count == 3)
    }
    
    @Test
    func testAddTaskAppendsAndPersists() async {
        let mock = MockStorageProvider()
        let vm = TaskListViewModel(storageProvider: mock)
        let newTask = Task(title: "New Task")
        await vm.addTask(task: newTask)
        #expect(vm.tasks.contains(where: { $0.id == newTask.id }))
        #expect(mock.saveCallCount == 1)
        #expect(mock.savedSnapshots.last?.contains(where: { $0.id == newTask.id }) == true)
    }
    
    @Test
    func testRemoveTasksRemovesAndPersists() async {
        let mock = MockStorageProvider()
        let vm = TaskListViewModel(storageProvider: mock)
        let initialCount = vm.tasks.count
        await vm.removeTasks(atOffsets: IndexSet(integer: 1))
        #expect(vm.tasks.count == initialCount - 1)
        #expect(mock.saveCallCount == 1)
    }
    
    @Test
    func testToggleCompletionPersists() async {
        let mock = MockStorageProvider()
        let vm = TaskListViewModel(storageProvider: mock)
        let task = vm.tasks[0]
        let initial = task.isCompleted
        await vm.toggleCompletion(task: task)
        #expect(vm.tasks[0].isCompleted != initial)
        #expect(mock.saveCallCount == 1)
    }
    
    @Test
    func testSaveTasksCallsStorage() async {
        let mock = MockStorageProvider()
        let vm = TaskListViewModel(storageProvider: mock)
        await vm.saveTasks()
        #expect(mock.saveCallCount == 1)
        #expect(mock.savedSnapshots.last == vm.tasks)
    }
    
    @Test
    func testAddThenRemoveMaintainsConsistency() async {
        let mock = MockStorageProvider()
        let vm = TaskListViewModel(storageProvider: mock)
        let added = Task(title: "Temp")
        await vm.addTask(task: added)
        let index = vm.tasks.firstIndex(where: { $0.id == added.id })!
        await vm.removeTasks(atOffsets: IndexSet(integer: index))
        #expect(vm.tasks.contains(where: { $0.id == added.id }) == false)
        #expect(mock.saveCallCount >= 2)
    }
    
    @Test
    func testMultipleAddsPersistSnapshots() async {
        let mock = MockStorageProvider()
        let vm = TaskListViewModel(storageProvider: mock)
        for i in 0..<3 {
            await vm.addTask(task: Task(title: "Task \(i)"))
        }
        #expect(mock.saveCallCount == 3)
        #expect(mock.savedSnapshots.last?.count == vm.tasks.count)
    }
}
