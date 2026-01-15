import SwiftUI
 
@MainActor
struct ChainEditView: View {
    @Environment(\.dismiss) private var dismiss
 
     let chainId: UUID
     let onSaved: () -> Void

     @State private var habitIds: [UUID] = []
     @State private var habitsById: [UUID: Habit] = [:]

     @State private var showAddSheet = false

     #if os(iOS)
     @State private var editMode: EditMode = .inactive
     #endif

     var body: some View {
         List {
             Section {
                 ForEach(habitIds, id: \.self) { id in
                     HStack(spacing: 12) {
                         Image(systemName: "line.3.horizontal")
                             .foregroundStyle(.secondary)

                         Text(habitsById[id]?.name ?? "—")
                             .foregroundStyle(.primary)

                         Spacer()

                         Button {
                             if let idx = habitIds.firstIndex(of: id) { habitIds.remove(at: idx) }
                         } label: {
                             Image(systemName: "trash").foregroundStyle(.secondary)
                         }
                         .buttonStyle(.plain)
                     }
                     .contentShape(Rectangle())
                 }
                 .onMove(perform: move)
                 .onDelete(perform: delete)
             } header: {
                 Text("Secuencia de la Rutina")
             } footer: {
                 Text("Arrastra para reordenar o elimina hábitos de la cadena.")
             }

             Section {
                 Button {
                     showAddSheet = true
                 } label: {
                     HStack {
                         Image(systemName: "plus")
                         Text("Añadir nuevo hábito")
                     }
                 }
             }
         }
         .navigationTitle("Editar Cadena")
         .toolbar {
             ToolbarItem(placement: .cancellationAction) {
                 Button("Cancelar") { dismiss() }
             }
             ToolbarItem(placement: .confirmationAction) {
                 Button("Guardar Cambios") { save() }
             }

             #if os(iOS)
             ToolbarItem(placement: .navigationBarTrailing) { reorderButton }
             #endif
         }
         .onAppear { load() }
         .sheet(isPresented: $showAddSheet) {
             NavigationStack {
                 AddHabitsToChainSheet(currentIds: habitIds) { newIds in
                     // añade (sin duplicar)
                     for id in newIds where !habitIds.contains(id) { habitIds.append(id) }
                     // recarga diccionario
                     let habits = ChainedHabitsStorage.fetchHabits(for: habitIds)
                     habitsById = Dictionary(uniqueKeysWithValues: habits.map { ($0.id, $0) })
                 }
             }
         }
         #if os(iOS)
         .environment(\.editMode, Binding<EditMode?>(
             get: { editMode },
             set: { editMode = $0 ?? .inactive }
         ))
         #endif
         #if os(macOS)
         .frame(minWidth: 420, minHeight: 520)
         #endif
     }

     #if os(iOS)
     private var isEditing: Bool { editMode == .active }

     private var reorderButton: some View {
         Button(isEditing ? "Listo" : "Reordenar") {
             withAnimation { editMode = isEditing ? .inactive : .active }
         }
         .disabled(habitIds.count < 2)
     }
     #endif

     private func load() {
         let items = ChainedHabitsStorage.fetchItems(chainId: chainId)
         habitIds = items.sorted(by: { $0.position < $1.position }).map(\.habitId)

         let habits = ChainedHabitsStorage.fetchHabits(for: habitIds)
         habitsById = Dictionary(uniqueKeysWithValues: habits.map { ($0.id, $0) })
     }

     private func move(from source: IndexSet, to destination: Int) {
         habitIds.move(fromOffsets: source, toOffset: destination)
     }

     private func delete(at offsets: IndexSet) {
         habitIds.remove(atOffsets: offsets)
     }

     private func save() {
         ChainedHabitsStorage.replaceItems(chainId: chainId, habitIds: habitIds)
         onSaved()
         dismiss()
     }
 }
 
@MainActor
private struct AddHabitsToChainSheet: View {
     @Environment(\.dismiss) private var dismiss
     @EnvironmentObject private var config: AppConfig

     let currentIds: [UUID]
     let onAdd: ([UUID]) -> Void

     @State private var available: [Habit] = []
     @State private var selected: Set<UUID> = []
     @State private var isLoading = true

     var body: some View {
         List {
             if isLoading {
                 HStack {
                     Spacer()
                     ProgressView()
                     Spacer()
                 }
                 .padding(.vertical, 24)
             } else if available.isEmpty {
                 Text("No hay hábitos disponibles para añadir.")
                     .foregroundStyle(.secondary)
                     .frame(maxWidth: .infinity, alignment: .center)
                     .padding(.vertical, 24)
             } else {
                 ForEach(available) { habit in
                     Button {
                         if selected.contains(habit.id) { selected.remove(habit.id) }
                         else { selected.insert(habit.id) }
                     } label: {
                         HStack {
                             Text(habit.name.isEmpty ? "—" : habit.name)
                             Spacer()
                             if selected.contains(habit.id) {
                                 Image(systemName: "checkmark")
                                     .foregroundStyle(Color.accentColor)
                             }
                         }
                     }
                     .buttonStyle(.plain)
                 }
             }
         }
         .navigationTitle("Añadir hábitos")
         .toolbar {
             ToolbarItem(placement: .cancellationAction) {
                 Button("Cerrar") { dismiss() }
             }
             ToolbarItem(placement: .confirmationAction) {
                 Button("Añadir") {
                     onAdd(Array(selected))
                     dismiss()
                 }
                 .disabled(selected.isEmpty)
             }
         }
         .task { await load() }
         #if os(macOS)
         .frame(minWidth: 420, minHeight: 520)
         #endif
     }

     private func load() async {
         isLoading = true
         defer { isLoading = false }

         let all: [Habit]
         if SwiftDataContext.shared != nil {
             all = ChainedHabitsStorage.fetchAllHabits()
         } else {
             all = (try? await config.storageProvider.loadHabits()) ?? []
         }

         let set = Set(currentIds)
         available = all.filter { !set.contains($0.id) }
     }
 }