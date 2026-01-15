//
//  HabitDetailView.swift
//  HabitApp
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

@MainActor
struct HabitDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var config: AppConfig

    @Binding var habit: Habit
    var onSave: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    @State private var showEditSheet = false
    @State private var didLoad = false

    @State private var category: HabitCategory?
    @State private var streak: HabitStreak?
    @State private var stats = HabitStats(completionRate: 0, totalCompletions: 0, currentStreak: 0, lastSevenDays: [])

    @State private var reminders: [HabitReminder] = []
    @State private var todayNote: HabitNote?
    @State private var noteText: String = ""
    @State private var recentNotes: [HabitNote] = []

    private var hasSwiftData: Bool { SwiftDataContext.shared != nil }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 18) {
                    headerSection

                    if config.enableStreaks || config.enableStatistics {
                        statsGrid
                    }

                    if config.enableReminders, hasSwiftData {
                        remindersCard
                    }

                    if config.enableDailyNotes, hasSwiftData {
                        notesSection
                    }

                    if !recentNotes.isEmpty {
                        Text("Últimos días")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.primary)
                            .padding(.leading, 2)
                            .padding(.top, 2)

                        VStack(spacing: 10) {
                            ForEach(recentNotes) { note in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(note.date, style: .date)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)

                                    Text(note.text)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                        .lineLimit(3)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(14)
                                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                                }
                            }
                        }
                    }

                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
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
                Text("Detalle de Hábito").font(.headline)
            }
        }
        #if os(iOS)
        .toolbarBackground(.thinMaterial, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        #endif
        .sheet(isPresented: $showEditSheet) {
            NavigationStack {
                EditHabitView(
                    habit: $habit,
                    onSave: { onSave?(); refresh() },
                    onDelete: { onDelete?() }
                )
            }
        }
        .onAppear {
            guard !didLoad else { return }
            didLoad = true
            refresh()
        }
        .onChange(of: noteText) { _, newValue in
            guard config.enableDailyNotes, hasSwiftData else { return }
            guard let note = todayNote else { return }
            NotesStorage.saveNote(note, text: newValue)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 120, height: 120)
                    .overlay {
                        if let data = habit.imageData,
                           let image = platformImage(from: data) {
                            image
                                .resizable()
                                .scaledToFill()
                                .clipShape(Circle())
                        } else {
                            Image(systemName: sfSymbol(for: habit.iconName))
                                .font(.system(size: 46, weight: .bold))
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .overlay { Circle().stroke(Color.white.opacity(0.9), lineWidth: 6) }
                    .clipped()
            }
            .padding(.top, 6)

            Text(habit.name.isEmpty ? "Nuevo hábito" : habit.name)
                .font(.title2.bold())
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)

            if config.enableCategories, hasSwiftData, let category {
                Text(category.name.uppercased())
                    .font(.caption.weight(.bold))
                    .foregroundStyle(category.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(category.color.opacity(0.14), in: Capsule())
            }

            if !habit.detail.isEmpty {
                Text(habit.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 340)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text("FRECUENCIA: \(habit.frequency.localizedName.uppercased())")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 6)
    }

    // MARK: - Stats

    private var statsGrid: some View {
        let currentStreakValue = config.enableStreaks ? (streak?.currentStreak ?? 0) : (stats.currentStreak)
        let bestStreakValue = config.enableStreaks ? (streak?.bestStreak ?? 0) : 0
        let compliance = Int((stats.completionRate * 100).rounded())

        return HStack(spacing: 12) {
            statCard(
                icon: "flame.fill",
                iconTint: .orange,
                value: "\(max(0, currentStreakValue))",
                title: "Racha\nActual"
            )

            statCard(
                icon: "trophy.fill",
                iconTint: .yellow,
                value: "\(max(0, bestStreakValue))",
                title: "Racha Máx"
            )

            statCard(
                icon: "circle.dotted",
                iconTint: .green,
                value: "\(min(100, max(0, compliance)))%",
                title: "Cumplimiento"
            )
        }
    }

    private func statCard(icon: String, iconTint: Color, value: String, title: String) -> some View {
        VStack(spacing: 10) {
            ZStack {
                Circle().fill(iconTint.opacity(0.16))
                Image(systemName: icon)
                    .foregroundStyle(iconTint)
                    .font(.system(size: 18, weight: .bold))
            }
            .frame(width: 44, height: 44)

            Text(value)
                .font(.title3.bold())
                .foregroundStyle(.primary)

            Text(title.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    // MARK: - Reminders

    private var remindersCard: some View {
        let timeText = reminderTimeLabel()
        let isOn = reminders.contains(where: { $0.isEnabled })

        return HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.accentColor.opacity(0.12))
                Image(systemName: "bell.fill")
                    .foregroundStyle(Color.accentColor)
                    .font(.system(size: 18, weight: .bold))
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text("Recordatorios")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.primary)
                Text(timeText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { isOn },
                set: { newValue in
                    setRemindersEnabled(newValue)
                }
            ))
            .labelsHidden()
            .tint(Color.accentColor)
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private func reminderTimeLabel() -> String {
        guard let firstEnabled = reminders.first(where: { $0.isEnabled }) else { return "—" }

        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "HH:mm a" // estilo tipo “20:00 PM” como tu mock
        return df.string(from: firstEnabled.reminderTime)
    }

    private func setRemindersEnabled(_ enabled: Bool) {
        guard config.enableReminders, hasSwiftData else { return }

        if enabled {
            if reminders.isEmpty {
                let time = defaultReminderTime()
                if let created = ReminderStorage.addReminder(habitId: habit.id, time: time, isEnabled: true) {
                    ReminderNotifications.requestPermissionIfNeeded()
                    Task {
                        await ReminderNotifications.schedule(
                            reminderId: created.id,
                            habitName: habit.name,
                            time: created.reminderTime,
                            weekdays: Set(created.repeatDays)
                        )
                    }
                }
            } else {
                for r in reminders {
                    r.isEnabled = true
                    ReminderStorage.save(r)
                    Task {
                        await ReminderNotifications.schedule(
                            reminderId: r.id,
                            habitName: habit.name,
                            time: r.reminderTime,
                            weekdays: Set(r.repeatDays)
                        )
                    }
                }
            }
        } else {
            for r in reminders {
                r.isEnabled = false
                ReminderStorage.save(r)
                ReminderNotifications.cancel(reminderId: r.id, weekdays: r.repeatDays)
            }
        }

        refresh()
    }

    private func defaultReminderTime() -> Date {
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month, .day], from: Date())
        comps.hour = 20
        comps.minute = 0
        return cal.date(from: comps) ?? Date()
    }

    // MARK: - Notes

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notas Diarias")
                .font(.title3.bold())
                .foregroundStyle(.primary)
                .padding(.leading, 2)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $noteText)
                    .frame(minHeight: 180)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    }

                if noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Escribe tu reflexión o progreso de hoy...")
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 22)
                }
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Bottom bar

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Button { completeToday() } label: {
                Text("Completar Día")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)

            Button { showEditSheet = true } label: {
                Text("Editar")
                    .font(.headline)
                    .foregroundStyle(Color.accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(.thinMaterial)
    }

    // MARK: - Actions

    private func completeToday() {
        habit.toggleCompletion()

        Task {
            await PluginRegistry.shared.notifyHabitCompletionDidChange(
                habitId: habit.id,
                isCompleted: habit.isCompletedForCurrentPeriod,
                completionDate: habit.lastCompletedDate
            )
        }

        onSave?()
        refresh()
    }

    // MARK: - Data

    private func refresh() {
        guard hasSwiftData else { return }

        if config.enableCategories {
            category = CategoryStorage.fetchCategory(for: habit.id)
        } else {
            category = nil
        }

        if config.enableStreaks {
            streak = StreakStorage.fetchStreak(habitId: habit.id)
        } else {
            streak = nil
        }

        if config.enableStatistics {
            stats = StatsCalculator.calculate(for: habit)
        } else {
            stats = HabitStats(completionRate: 0, totalCompletions: 0, currentStreak: 0, lastSevenDays: [])
        }

        if config.enableReminders {
            reminders = ReminderStorage.fetchReminders(for: habit.id)
        } else {
            reminders = []
        }

        if config.enableDailyNotes {
            let note = NotesStorage.loadOrCreateTodayNote(habitId: habit.id, today: Date())
            todayNote = note
            noteText = note?.text ?? ""

            recentNotes = NotesStorage.fetchRecentNotes(habitId: habit.id, today: Date())
        } else {
            todayNote = nil
            noteText = ""
            recentNotes = []
        }
    }

    // MARK: - Media helpers

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

#Preview {
    NavigationStack {
        HabitDetailView(
            habit: .constant(Habit(name: "Leer 30 minutos", description: "Leer al menos 30 minutos de un libro de no ficción para mejorar el aprendizaje continuo.", frequency: .daily)),
            onSave: {},
            onDelete: {}
        )
        .environmentObject(AppConfig())
    }
}