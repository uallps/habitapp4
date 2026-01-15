import SwiftUI

struct DueDateDetailView: View {
    @StateObject private var viewModel: DueDateViewModel

    init(habitId: UUID) {
        _viewModel = StateObject(wrappedValue: DueDateViewModel(
            habitId: habitId,
            storageProvider: DueDateSwiftDataStorageProvider()
        ))
    }

    var body: some View {
        Section("Fecha de Vencimiento (Ejemplo)") {
            Toggle("Tiene vencimiento", isOn: Binding(
                get: { viewModel.hasDueDate },
                set: { _ in viewModel.toggleDueDate() }
            ))
            
            if viewModel.hasDueDate, let dueDate = viewModel.dueDate {
                DatePicker("Fecha de Vencimiento", selection: Binding(
                    get: { dueDate },
                    set: { viewModel.setDueDate($0) }
                ), displayedComponents: .date)
            }
        }
    }
}
