//
//  HabitListView.swift
//  HabitApp
//
import SwiftData
import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

struct HabitListView: View {
    let storageProvider: StorageProvider
    @StateObject private var viewModel: HabitListViewModel
    @State private var showingAddHabit = false

    init(storageProvider: StorageProvider) {
        self.storageProvider = storageProvider
        _viewModel = StateObject(wrappedValue: HabitListViewModel(storageProvider: storageProvider))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Resumen Semanal")
                        .font(.title2.bold())
                        .padding(.top, 6)

                    WeeklySummaryCard(habits: activeHabits)

                    Text("Hábitos Diarios")
                        .font(.title2.bold())
                        .padding(.top, 6)

                    LazyVStack(spacing: 12) {
                        if viewModel.habits.isEmpty {
                            Text("Aún no hay hábitos.")
                                .foregroundStyle(.secondary)
                                .padding(.vertical, 24)
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            ForEach(viewModel.habits) { habit in
                                HabitDashboardRow(
                                    habit: habit,
                                    destination: AnyView({
                                        #if PREMIUM
                                        if let chainId = ChainedHabitsStorage.fetchChainId(containing: habit.id) {
                                            return AnyView(ChainedHabitDetailView(chainId: chainId))
                                        }
                                        #endif

                                        return AnyView(HabitDetailView(
                                            habit: binding(for: habit),
                                            onSave: {
                                                Task {
                                                    await viewModel.saveHabits()
                                                    NotificationCenter.default.post(name: .habitsDidChange, object: nil)
                                                }
                                            }
                                        ))
                                    }()),
                                    onToggle: { await viewModel.toggleHabitCompletion(habit: habit) },
                                    onDelete: { await viewModel.removeHabit(habit) }
                                )
                            }
                        }
                    }
                }
                .padding(16)
            }
            #if os(iOS)
            .background(Color(.systemGroupedBackground))
            #else
            .background(Color(nsColor: .windowBackgroundColor))
            #endif
            .navigationTitle("")
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .principal) {
                    Text("Mis Hábitos").font(.headline)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    addButton
                }
                #else
                ToolbarItem(placement: .principal) {
                    Text("Mis Hábitos").font(.headline)
                }
                ToolbarItem(placement: .primaryAction) {
                    addButton
                }
                #endif
            }
            #if os(iOS)
            .toolbarBackground(.thinMaterial, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            #endif
            .sheet(isPresented: $showingAddHabit) {
                AddHabitView(storageProvider: storageProvider) { newHabit in
                    Task {
                        await viewModel.addHabit(habit: newHabit)
                        showingAddHabit = false
                    }
                }
            }
            .task {
                await viewModel.loadHabits()
            }
            .onReceive(NotificationCenter.default.publisher(for: .habitsDidChange)) { _ in
                Task { await viewModel.loadHabits() }
            }
        }
    }

    private var addButton: some View {
        Button(action: { showingAddHabit = true }) {
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color.accentColor.opacity(0.2)))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Añadir hábito")
    }

    private var activeHabits: [Habit] {
        viewModel.habits.filter { $0.isActive }
    }

    private func binding(for habit: Habit) -> Binding<Habit> {
        guard let index = viewModel.habits.firstIndex(where: { $0.id == habit.id }) else {
            fatalError("Habit not found")
        }
        return $viewModel.habits[index]
    }
}

// MARK: - Components

private struct HabitDashboardRow<Destination: View>: View {
    let habit: Habit
    let destination: Destination
    let onToggle: () async -> Void
    let onDelete: () async -> Void

    @State private var isToggling = false

    var body: some View {
        HStack(spacing: 12) {
            Button {
                Task {
                    isToggling = true
                    await onToggle()
                    isToggling = false
                }
            } label: {
                Image(systemName: habit.isCompletedForCurrentPeriod ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(habit.isCompletedForCurrentPeriod ? Color.green : Color.secondary)
            }
            .buttonStyle(.plain)
            .disabled(isToggling)

            NavigationLink {
                destination
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(habit.name)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 8)

                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.secondary.opacity(0.12))
                        .frame(width: 64, height: 64)
                        .overlay { habitMedia }
                        .clipped()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            #if PREMIUM
            HStack(spacing: 6) {
                Image(systemName: "medal.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.yellow)

                Text("+\(RewardsStorage.xp(for: habit)) XP")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.yellow)
            }
            #endif
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contextMenu {
            Button(role: .destructive) {
                Task { await onDelete() }
            } label: {
                Label("Eliminar", systemImage: "trash")
            }
        }
    }

    private var subtitle: String {
        if !habit.detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return habit.detail
        }
        return habit.frequency.rawValue
    }

    @ViewBuilder
    private var habitMedia: some View {
        if let data = habit.imageData,
           let image = platformImage(from: data) {
            image
                .resizable()
                .scaledToFill()
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        } else {
            Image(systemName: sfSymbol(for: habit.iconName))
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.secondary.opacity(0.7))
        }
    }

    private func sfSymbol(for materialName: String?) -> String {
        switch materialName {
        case "menu_book": return "book.fill"
        case "dumbbell": return "dumbbell.fill"
        case "figure.mind.and.body": return "figure.mind.and.body"
        case "drop": return "drop.fill"
        case .none: return "photo"
        default: return "ellipsis"
        }
    }

    private func platformImage(from data: Data) -> Image? {
        #if os(iOS)
        if let ui = UIImage(data: data) { return Image(uiImage: ui) }
        #else
        if let ns = NSImage(data: data) { return Image(nsImage: ns) }
        #endif
        return nil
    }
}

private struct WeeklySummaryCard: View {
    let habits: [Habit]

    var body: some View {
        let metrics = WeeklyMetrics(habits: habits)

        VStack(alignment: .leading, spacing: 12) {
            Text("Hábitos Completados")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            Text("\(Int((metrics.thisWeekAverage * 100).rounded()))%")
                .font(.system(size: 44, weight: .bold, design: .default))
                .foregroundStyle(.primary)

            HStack(spacing: 10) {
                Text("Esta semana")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(metrics.deltaText)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(metrics.deltaColor)
            }

            HStack(alignment: .bottom, spacing: 12) {
                ForEach(metrics.bars) { bar in
                    VStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color.accentColor.opacity(bar.isToday ? 1.0 : 0.2))
                            .frame(width: 14, height: max(6, bar.value * 120))

                        Text(bar.label)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct WeeklyMetrics {
    struct DayBar: Identifiable {
        let id = UUID()
        let label: String
        let value: CGFloat
        let isToday: Bool
    }

    let bars: [DayBar]
    let thisWeekAverage: Double
    let delta: Double

    init(habits: [Habit]) {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Lunes
        let now = Date()

        let total = max(1, habits.count)
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? calendar.startOfDay(for: now)
        let startOfLastWeek = calendar.date(byAdding: .day, value: -7, to: startOfWeek) ?? startOfWeek

        let labels = ["L", "M", "X", "J", "V", "S", "D"]

        func weekBars(start: Date) -> [DayBar] {
            (0..<7).map { offset in
                let dayDate = calendar.date(byAdding: .day, value: offset, to: start) ?? start
                let completedCount = habits.reduce(0) { partial, habit in
                    guard let last = habit.lastCompletedDate else { return partial }
                    return partial + (calendar.isDate(last, inSameDayAs: dayDate) ? 1 : 0)
                }
                return DayBar(
                    label: labels.indices.contains(offset) ? labels[offset] : "",
                    value: CGFloat(Double(completedCount) / Double(total)),
                    isToday: calendar.isDate(dayDate, inSameDayAs: now)
                )
            }
        }

        let thisWeekBars = weekBars(start: startOfWeek)
        let lastWeekBars = weekBars(start: startOfLastWeek)

        self.bars = thisWeekBars
        self.thisWeekAverage = thisWeekBars.map { Double($0.value) }.reduce(0, +) / 7.0
        let lastWeekAverage = lastWeekBars.map { Double($0.value) }.reduce(0, +) / 7.0
        self.delta = thisWeekAverage - lastWeekAverage
    }

    var deltaText: String {
        let pct = Int((delta * 100).rounded())
        return pct >= 0 ? "+\(pct)%" : "\(pct)%"
    }

    var deltaColor: Color {
        delta >= 0 ? .green : .red
    }
}

#Preview {
    HabitListView(storageProvider: MockStorageProvider())
}

