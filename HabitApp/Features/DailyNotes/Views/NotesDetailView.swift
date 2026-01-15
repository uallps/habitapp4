import SwiftUI

struct NotesDetailView: View {
    let habitId: UUID
    let isEnabled: Bool

    @State private var todayNote: HabitNote?
    @State private var noteText = ""
    @State private var recentNotes: [HabitNote] = []

    var body: some View {
        Group {
            if isEnabled {
                Section("Nota de Hoy") {
                    TextField("Escribe una nota sobre este hábito", text: $noteText, axis: .vertical)
                        .lineLimit(3...6)
                        .onChange(of: noteText) { _, newValue in
                            if let todayNote {
                                NotesStorage.saveNote(todayNote, text: newValue)
                            }
                        }
                }

                if !recentNotes.isEmpty {
                    Section("Notas Recientes") {
                        ForEach(recentNotes) { note in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(note.date, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(note.text)
                                    .font(.body)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
        .task { @MainActor in
            await load()
        }
    }

    @MainActor private func load() async {
        let today = Date()
        todayNote = NotesStorage.loadOrCreateTodayNote(habitId: habitId, today: today)
        noteText = todayNote?.text ?? ""
        recentNotes = NotesStorage.fetchRecentNotes(habitId: habitId, today: today)
    }
}