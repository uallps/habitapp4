import SwiftUI

struct NotesRowView: View {
    let habitId: UUID
    let isEnabled: Bool

    @State private var hasTodayNote = false

    var body: some View {
        Group {
            if isEnabled && hasTodayNote {
                Image(systemName: "note.text")
                    .foregroundColor(.blue)
                    .font(.caption)
            }
        }
        .task {
            hasTodayNote = NotesStorage.hasTodayNote(habitId: habitId, today: Date())
        }
    }
}