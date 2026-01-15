import Testing
import Foundation
@testable import HabitApp

// MARK: - Mocks

final class MockStorageProvider: StorageProvider {
    var loadResult: [Habit] = []
    var savedSnapshots: [[Habit]] = []
    var saveCallCount = 0
    var shouldThrowOnLoad = false
    var shouldThrowOnSave = false
    
    init(loadResult: [Habit] = []) {
        self.loadResult = loadResult
    }
    
    func loadHabits() async throws -> [Habit] {
        if shouldThrowOnLoad { throw MockError.load }
        return loadResult
    }
    
    func saveHabits(habits: [Habit]) async throws {
        if shouldThrowOnSave { throw MockError.save }
        saveCallCount += 1
        savedSnapshots.append(habits)
    }
    
    enum MockError: Error { case load, save }
}

// MARK: - Tests

@MainActor
struct HabitListViewModelTests {
    
    @Test
    func testInitialDefaultHabits() async {
        let vm = HabitListViewModel(storageProvider: MockStorageProvider())
        #expect(vm.habits.count == 3)
        #expect(vm.habits.map(\.name).contains("Comprar leche"))
    }
    
    @Test
    func testLoadHabitsReplacesDefaults() async {
        let loaded = [
            Habit(name: "A", frequency: .daily),
            Habit(name: "B", frequency: .weekly),
            Habit(name: "C", frequency: .monthly)
        ]
        let mock = MockStorageProvider(loadResult: loaded)
        let vm = HabitListViewModel(storageProvider: mock)
        await vm.loadHabits()
        #expect(vm.habits == loaded)
    }
    
    @Test
    func testLoadHabitsErrorDoesNotCrash() async {
        let mock = MockStorageProvider()
        mock.shouldThrowOnLoad = true
        let vm = HabitListViewModel(storageProvider: mock)
        await vm.loadHabits()
        // Fallback: habits remain default
        #expect(vm.habits.count == 3)
    }
    
    @Test
    func testAddHabitAppendsAndPersists() async {
        let mock = MockStorageProvider()
        let vm = HabitListViewModel(storageProvider: mock)
        let newHabit = Habit(name: "Nuevo", frequency: .daily)
        await vm.addHabit(habit: newHabit)
        #expect(vm.habits.contains(where: { $0.id == newHabit.id }))
        #expect(mock.saveCallCount == 1)
        #expect(mock.savedSnapshots.last?.contains(where: { $0.id == newHabit.id }) == true)
    }
    
    @Test
    func testRemoveHabitsRemovesAndPersists() async {
        let mock = MockStorageProvider()
        let vm = HabitListViewModel(storageProvider: mock)
        let initialCount = vm.habits.count
        await vm.removeHabits(atOffsets: IndexSet(integer: 1))
        #expect(vm.habits.count == initialCount - 1)
        #expect(mock.saveCallCount == 1)
    }
    
    @Test
    func testToggleCompletionPersists() async {
        let mock = MockStorageProvider()
        let vm = HabitListViewModel(storageProvider: mock)
        let habit = vm.habits[0]
        let initial = habit.isCompletedForCurrentPeriod
        await vm.toggleHabitCompletion(habit: habit)
        #expect(vm.habits[0].isCompletedForCurrentPeriod != initial)
        #expect(mock.saveCallCount == 1)
    }
    
    @Test
    func testSaveHabitsCallsStorage() async {
        let mock = MockStorageProvider()
        let vm = HabitListViewModel(storageProvider: mock)
        await vm.saveHabits()
        #expect(mock.saveCallCount == 1)
        #expect(mock.savedSnapshots.last == vm.habits)
    }
    
    @Test
    func testAddThenRemoveMaintainsConsistency() async {
        let mock = MockStorageProvider()
        let vm = HabitListViewModel(storageProvider: mock)
        let added = Habit(name: "Temp", frequency: .daily)
        await vm.addHabit(habit: added)
        let index = vm.habits.firstIndex(where: { $0.id == added.id })!
        await vm.removeHabits(atOffsets: IndexSet(integer: index))
        #expect(vm.habits.contains(where: { $0.id == added.id }) == false)
        #expect(mock.saveCallCount >= 2)
    }
    
    @Test
    func testMultipleAddsPersistSnapshots() async {
        let mock = MockStorageProvider()
        let vm = HabitListViewModel(storageProvider: mock)
        for i in 0..<3 {
            await vm.addHabit(habit: Habit(name: "Habit \(i)", frequency: .daily))
        }
        #expect(mock.saveCallCount == 3)
        #expect(mock.savedSnapshots.last?.count == vm.habits.count)
    }
}
