import SwiftUI
import UserNotifications

struct ReminderSettingsView: View {
    @ObservedObject var config: AppConfig
    @State private var notificationStatus = "Desconocido"

    var body: some View {
        Section("Recordatorios") {
            Toggle("Habilitar", isOn: $config.enableReminders)

            if config.enableReminders {
                HStack {
                    Text("Estado de notificaciones").foregroundColor(.secondary)
                    Spacer()
                    Text(notificationStatus)
                        .foregroundColor(notificationStatus == "Autorizado" ? .green : .orange)
                }
                .font(.caption)

                Text("Configura recordatorios para cada hábito")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .task { await checkNotificationStatus() }
    }

    private func checkNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized:     notificationStatus = "Autorizado"
        case .denied:         notificationStatus = "Denegado"
        case .notDetermined:  notificationStatus = "No configurado"
        case .provisional:    notificationStatus = "Provisional"
        case .ephemeral:      notificationStatus = "Efímero"
        @unknown default:     notificationStatus = "Desconocido"
        }
    }
}