import SwiftUI
import SwiftData

@MainActor
struct ChainedHabitDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let chainId: UUID

    @State private var title: String = "Hábito Encadenado"
    @State private var rows: [Row] = []
    @State private var progressText: String = "0/0 completados"
    @State private var progressValue: Double = 0
    @State private var showEditChain = false

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 16) {
                    header

                    chainCard

                    VStack(spacing: 12) {
                        statCardLeft
                        statCardRight
                    }

                    Spacer(minLength: 110)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 8)
            }

            bottomBar
        }
        #if os(iOS)
        .background(Color(.systemGroupedBackground))
        #else
        .background(Color(nsColor: .windowBackgroundColor))
        #endif
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Hábito").font(.headline)
            }
        }
        .onAppear { load() }
        .sheet(isPresented: $showEditChain) {
            NavigationStack {
                ChainEditView(chainId: chainId) {
                    load()
                }
            }
        }
    }

    // MARK: UI

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.accentColor.opacity(0.14))
                Image(systemName: "link")
                    .foregroundStyle(Color.accentColor)
                    .font(.system(size: 18, weight: .bold))
            }
            .frame(width: 48, height: 48)

            Text(title)
                .font(.title2.bold())
                .foregroundStyle(.primary)

            Spacer()
        }
    }

    private var chainCard: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.thinMaterial)

            // Línea vertical punteada
            Rectangle()
                .fill(Color.clear)
                .overlay(
                    Rectangle()
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [6, 6]))
                        .foregroundStyle(Color.secondary.opacity(0.35))
                )
                .frame(width: 2)
                .padding(.leading, 26)
                .padding(.vertical, 18)

            VStack(spacing: 18) {
                ForEach(rows) { row in
                    timelineRow(row)
                }
            }
            .padding(16)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private func timelineRow(_ row: Row) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle().fill(row.dotColor)
                Image(systemName: row.dotIcon)
                    .foregroundStyle(row.dotIconColor)
                    .font(.system(size: 16, weight: .bold))
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 10) {
                    Text(row.title)
                        .font(.headline)
                        .foregroundStyle(row.titleColor)

                    Spacer(minLength: 0)

                    Text(row.badgeText)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(row.badgeTextColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(row.badgeBg, in: Capsule())
                }

                Text(row.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(row.subtitleColor)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(row.cardBg, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private var statCardLeft: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Racha actual")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(progressText)
                .font(.title2.bold())
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private var statCardRight: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Progreso del día")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ProgressView(value: progressValue)
                .tint(Color.accentColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Button {
                markActiveAsCompleted()
            } label: {
                Text("Marcar como completado")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!rows.contains(where: { $0.status == .active }))

            Button {
                showEditChain = true
            } label: {
                Text("Editar cadena")
                    .font(.headline)
                    .foregroundStyle(Color.accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(.thinMaterial)
    }

    // MARK: Data

    private func load() {
        guard SwiftDataContext.shared != nil else { return }

        let chain = ChainedHabitsStorage.fetchChain(chainId: chainId)
        title = chain?.name ?? "Hábito Encadenado"

        let items = ChainedHabitsStorage.fetchItems(chainId: chainId)
        let habitIds = items.map(\.habitId)
        let habits = ChainedHabitsStorage.fetchHabits(for: habitIds)
        let byId = Dictionary(uniqueKeysWithValues: habits.map { ($0.id, $0) })

        let ordered: [(HabitChainItem, Habit)] = items.compactMap { item in
            guard let h = byId[item.habitId] else { return nil }
            return (item, h)
        }

        let firstIncompleteIndex = ordered.firstIndex(where: { !$0.1.isCompletedForCurrentPeriod })

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "es_ES")
        formatter.dateStyle = .long
        formatter.timeStyle = .none

        rows = ordered.enumerated().map { idx, pair in
            let habit = pair.1
            let isCompleted = habit.isCompletedForCurrentPeriod
            let isActive = (!isCompleted && firstIncompleteIndex == idx)
            let status: Status = isCompleted ? .completed : (isActive ? .active : .pending)

            let badge: (String, Color, Color) = {
                switch status {
                case .completed: return ("Completado", .green, Color.green.opacity(0.15))
                case .active: return ("Activo", .blue, Color.blue.opacity(0.15))
                case .pending: return ("Pendiente", .secondary, Color.secondary.opacity(0.12))
                }
            }()

            let subtitle: String = {
                switch status {
                case .completed:
                    if let d = habit.lastCompletedDate {
                        return "Completado el \(formatter.string(from: d))"
                    }
                    return "Completado"
                case .active:
                    return "Activo"
                case .pending:
                    if idx > 0 {
                        let prev = ordered[idx - 1].1.name
                        return "Inicia después de \(prev)"
                    }
                    return "Pendiente"
                }
            }()

            let (dotColor, dotIcon, dotIconColor): (Color, String, Color) = {
                switch status {
                case .completed: return (.green, "checkmark", .white)
                case .active: return (Color.accentColor, "book.fill", .white)
                case .pending: return (Color.secondary.opacity(0.25), "dumbbell.fill", .secondary)
                }
            }()

            return Row(
                id: pair.0.id,
                habitId: habit.id,
                title: habit.name,
                subtitle: subtitle,
                status: status,
                badgeText: badge.0,
                badgeTextColor: badge.1,
                badgeBg: badge.2,
                dotColor: dotColor,
                dotIcon: dotIcon,
                dotIconColor: dotIconColor,
                cardBg: status == .pending ? Color.secondary.opacity(0.06) : Color.primary.opacity(0.05),
                titleColor: status == .pending ? .secondary : .primary,
                subtitleColor: .secondary
            )
        }

        let total = rows.count
        let done = rows.filter { $0.status == .completed }.count
        progressText = "\(done)/\(max(1, total)) completados"
        progressValue = total == 0 ? 0 : Double(done) / Double(total)
    }

    private func markActiveAsCompleted() {
        guard let active = rows.first(where: { $0.status == .active }) else { return }
        guard let ctx = SwiftDataContext.shared else { return }

        // Busca el Habit y márcalo
        let habitId = active.habitId
        let fetch = FetchDescriptor<Habit>(predicate: #Predicate<Habit> { $0.id == habitId })
        guard let habit = try? ctx.fetch(fetch).first else { return }

        habit.toggleCompletion()
        try? ctx.save()

        Task {
            await PluginRegistry.shared.notifyHabitCompletionDidChange(
                habitId: habit.id,
                isCompleted: habit.isCompletedForCurrentPeriod,
                completionDate: habit.lastCompletedDate
            )
        }

        load()
    }

    // MARK: Types

    private enum Status { case completed, active, pending }

    private struct Row: Identifiable {
        let id: UUID
        let habitId: UUID
        let title: String
        let subtitle: String
        let status: Status

        let badgeText: String
        let badgeTextColor: Color
        let badgeBg: Color

        let dotColor: Color
        let dotIcon: String
        let dotIconColor: Color

        let cardBg: Color
        let titleColor: Color
        let subtitleColor: Color
    }
}