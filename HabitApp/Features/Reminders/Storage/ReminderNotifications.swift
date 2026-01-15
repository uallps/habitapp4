import Foundation
import UserNotifications

enum ReminderNotifications {
    static func requestPermission() async {
        do {
            try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("Error requesting notification permission: \(error)")
        }
    }

    static func requestPermissionIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            Task { await requestPermission() }
        }
    }

    static func cancel(reminderId: UUID, weekdays: [Int]) {
        let identifiers = weekdays.map { "\(reminderId.uuidString)-\($0)" }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    static func schedule(
        reminderId: UUID,
        habitName: String,
        time: Date,
        weekdays: Set<Int>
    ) async {
        cancel(reminderId: reminderId, weekdays: Array(weekdays))

        let content = UNMutableNotificationContent()
        content.title = "Recordatorio de Hábito"
        content.body = "Es hora de: \(habitName)"
        content.sound = .default

        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)

        for day in weekdays {
            var dateComponents = DateComponents()
            dateComponents.hour = components.hour
            dateComponents.minute = components.minute
            dateComponents.weekday = day

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let identifier = "\(reminderId.uuidString)-\(day)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            try? await UNUserNotificationCenter.current().add(request)
        }
    }
}