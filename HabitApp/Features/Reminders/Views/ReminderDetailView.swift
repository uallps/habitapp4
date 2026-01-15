import SwiftUI

struct ReminderDetailView: View {
    @Binding var habit: Habit
    let isEnabled: Bool

    @State private var reminders: [HabitReminder] = []
    @State private var remindersEnabled: Bool = false

    var body: some View {
        if isEnabled {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Recordatorios", systemImage: "bell")
                        .foregroundStyle(.secondary)

                    Spacer()

                    Toggle("", isOn: $remindersEnabled)
                        .labelsHidden()
                        .tint(Color.accentColor)
                        .onChange(of: remindersEnabled) { _, newValue in
                            Task { await setAllEnabled(newValue) }
                        }
                }

                if remindersEnabled {
                    VStack(spacing: 10) {
                        ForEach(reminders) { r in
                            HStack(spacing: 12) {
                                Image(systemName: "bell.fill")
                                    .foregroundStyle(Color.accentColor)

                                DatePicker(
                                    "",
                                    selection: Binding(
                                        get: { r.reminderTime },
                                        set: { newValue in
                                            r.reminderTime = newValue
                                            ReminderStorage.save(r)

                                            if r.isEnabled {
                                                Task {
                                                    await ReminderNotifications.schedule(
                                                        reminderId: r.id,
                                                        habitName: habit.name,
                                                        time: newValue,
                                                        weekdays: Set(r.repeatDays)
                                                    )
                                                }
                                            }
                                        }
                                    ),
                                    displayedComponents: .hourAndMinute
                                )
                                .labelsHidden()

                                Spacer()

                                Button {
                                    ReminderNotifications.cancel(reminderId: r.id, weekdays: r.repeatDays)
                                    ReminderStorage.deleteReminder(r)
                                    Task { await load() }
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(12)
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                            }
                        }

                        Button {
                            guard let created = ReminderStorage.addReminder(
                                habitId: habit.id,
                                time: Date(),
                                isEnabled: true,
                                repeatDays: defaultRepeatDays()
                            ) else { return }

                            Task {
                                await ReminderNotifications.schedule(
                                    reminderId: created.id,
                                    habitName: habit.name,
                                    time: created.reminderTime,
                                    weekdays: Set(created.repeatDays)
                                )
                                await load()
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                Text("Añadir recordatorio")
                            }
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color.accentColor)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    Text("Sin recordatorios")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .task { await load() }
        }
    }

    @MainActor
    private func load() async {
        reminders = ReminderStorage.fetchReminders(for: habit.id)
        remindersEnabled = reminders.contains(where: { $0.isEnabled })
    }

    private func defaultRepeatDays() -> [Int] {
        switch habit.frequency {
        case .weekly:
            return habit.repeatDays.isEmpty ? [1,2,3,4,5,6,7] : habit.repeatDays
        default:
            return [1,2,3,4,5,6,7]
        }
    }

    private func setAllEnabled(_ enabled: Bool) async {
        await load()

        if enabled, reminders.isEmpty {
            _ = ReminderStorage.addReminder(
                habitId: habit.id,
                time: Date(),
                isEnabled: true,
                repeatDays: defaultRepeatDays()
            )
            await load()
        }

        for r in reminders {
            r.isEnabled = enabled
            ReminderStorage.save(r)

            if enabled {
                await ReminderNotifications.schedule(
                    reminderId: r.id,
                    habitName: habit.name,
                    time: r.reminderTime,
                    weekdays: Set(r.repeatDays)
                )
            } else {
                ReminderNotifications.cancel(reminderId: r.id, weekdays: r.repeatDays)
            }
        }
    }
}