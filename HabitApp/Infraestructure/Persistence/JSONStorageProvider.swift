import Foundation

@MainActor
final class JSONStorageProvider: StorageProvider {
    static let shared = JSONStorageProvider()
    
    private let fileManager = FileManager.default
    private let fileName = "habits.json"
    
    private var documentURL: URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent(fileName)
    }
    
    private init() {}
    
    func loadHabits() async throws -> [Habit] {
        if fileManager.fileExists(atPath: documentURL.path) {
            let data = try Data(contentsOf: documentURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([Habit].self, from: data)
        }
        return []
    }
    
    func saveHabits(habits: [Habit]) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(habits)
        try data.write(to: documentURL, options: .atomic)
    }
}
