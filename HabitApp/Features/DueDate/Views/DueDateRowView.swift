import SwiftUI

struct DueDateRowView: View {
    @ObservedObject var viewModel: DueDateViewModel

    var body: some View {
        if viewModel.hasDueDate, let dueDate = viewModel.dueDate {
            Text("Vence: \(dueDate.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
