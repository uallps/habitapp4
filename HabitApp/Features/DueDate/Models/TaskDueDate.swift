import Foundation
import SwiftData

@Model
final class TaskDueDate: Codable {
    enum CodingKeys: String, CodingKey {
        case taskUid, dueDate
    }
    
    var taskUid: UUID
    var dueDate: Date?
    
    init(taskUid: UUID, dueDate: Date?) {
        self.taskUid = taskUid
        self.dueDate = dueDate
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        taskUid = try container.decode(UUID.self, forKey: .taskUid)
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(taskUid, forKey: .taskUid)
        try container.encodeIfPresent(dueDate, forKey: .dueDate)
    }
}
