import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appConfig: AppConfig

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.95, green: 0.97, blue: 1.0),
                    Color.white
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Encabezado
                VStack(alignment: .leading, spacing: 8) {
                    Text("Ajustes")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text("Personaliza tu experiencia")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Sección: Características
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Características")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                            
                            VStack(spacing: 12) {
                                ForEach(Array(PluginRegistry.shared.getPluginSettingsViews().enumerated()), id: \.offset) { _, view in
                                    view
                                }
                            }
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                        
                        // Sección: General
                        VStack(alignment: .leading, spacing: 12) {
                            Text("General")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                            
                            VStack(spacing: 12) {
                                HStack {
                                    Label("Mostrar Prioridades", systemImage: "flag.fill")
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Toggle("", isOn: $appConfig.showPriorities)
                                        .tint(Color(red: 0.2, green: 0.6, blue: 1.0))
                                }
                                
                                Divider()
                                
                                #if PREMIUM
                                HStack {
                                    Label("Habilitar Recordatorios", systemImage: "bell.fill")
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Toggle("", isOn: $appConfig.enableReminders)
                                        .tint(Color(red: 0.2, green: 0.6, blue: 1.0))
                                }
                                
                                Divider()
                                #endif
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Tipo de Almacenamiento")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    
                                    Picker("Almacenamiento", selection: $appConfig.storageType) {
                                        ForEach(StorageType.allCases) { type in
                                            Text(type.rawValue).tag(type)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                    .tint(Color(red: 0.2, green: 0.6, blue: 1.0))
                                }
                            }
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                        
                        // Sección: Información
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Acerca de")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                            
                            VStack(spacing: 12) {
                                HStack {
                                    Text("Versión")
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("1.0.0")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.black)
                                }
                                
                                Divider()
                                
                                HStack {
                                    Text("Desarrollador")
                                        .foregroundColor(.gray)
                                    Spacer()
                                    Text("TaskApp Team")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.black)
                                }
                            }
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppConfig())
}
