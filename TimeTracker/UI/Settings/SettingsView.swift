import SwiftUI
import OSLog
import EventKit
import Factory

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TimeTracker", category: "CalendarService")


struct SettingsView: View {

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @Injected(\.calendarService) private var calendarService
    @State private var showingPrefixPicker = false
    @State private var isAccessRequestDeclined = false
    
    @AppStorage("calendarPrefix") var calendarPrefix: String = "⏱️"
    @AppStorage("selectedTheme") private var selectedTheme: Theme = .system
    
    @State private var alert: AlertModel?
    
    var body: some View {
        Form {
            Section("Оформление") {
                Picker("Тема", selection: $selectedTheme) {
                    ForEach(Theme.allCases) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
            }
            
            Section(
                header: Text("Префикс календарей"),
                footer: Text("Приложение будет работать только с календарями, содержащими выбранный префикс в названии")
            ) {
                
                HStack {
                    Text("Текущий префикс")
                    Spacer()
                    Button(calendarPrefix) {
                        showingPrefixPicker = true
                    }
                    .foregroundColor(.blue)
                }
            }
            
            Section(
                header: Text("Доступ к календарю"),
                footer: Text(calendarAccessFooter)
            ) {
                HStack {
                    Text("Текущий доступ")
                    Spacer()
                    Text(calendarAccessTitle)
                        .foregroundColor(.secondary)
                }
                
                if canChangeCalendarAccess {
                    if opensSystemSettings {
                        Button("Открыть настройки iOS") {
                            openSystemSettings()
                        }
                    } else {
                        Button("Запросить полный доступ") {
                            Task {
                                isAccessRequestDeclined = await !calendarService.requestFullAccess()
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Настройки")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Готово") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingPrefixPicker) {
            PrefixPickerView(selectedPrefix: $calendarPrefix)
        }
        .alert(item: $alert) { $0.asAlert }
        .onAppear {
            calendarService.refreshAuthorizationStatus()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                calendarService.refreshAuthorizationStatus()
            }
        }
    }
    
    private var canChangeCalendarAccess: Bool {
        switch calendarService.authorizationStatus {
        case .fullAccess, .authorized, .restricted:
            return false
        default:
            return true
        }
    }
    
    // iOS показывает системный запрос только один раз: после отказа доступ меняется в настройках iOS
    private var opensSystemSettings: Bool {
        calendarService.authorizationStatus == .denied || isAccessRequestDeclined
    }
    
    private var calendarAccessTitle: String {
        switch calendarService.authorizationStatus {
        case .fullAccess, .authorized:
            return "Полный"
        case .writeOnly:
            return "Только запись"
        case .denied:
            return "Запрещён"
        case .restricted:
            return "Ограничен"
        case .notDetermined:
            return "Не запрошен"
        @unknown default:
            return "Неизвестно"
        }
    }
    
    private var calendarAccessFooter: String {
        switch calendarService.authorizationStatus {
        case .fullAccess, .authorized:
            return "Приложение может создавать события и читать их для статистики"
        case .restricted:
            return "Доступ ограничен на этом устройстве, например, родительским контролем"
        default:
            if opensSystemSettings {
                return "Повторный запрос iOS не показывает. Откройте настройки iOS и выберите «Календари» → «Полный доступ»"
            }
            return "Полный доступ нужен, чтобы читать события и формировать статистику"
        }
    }
    
    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        openURL(url)
    }
}

struct PrefixPickerView: View {
    @Binding var selectedPrefix: String
    @Environment(\.dismiss) private var dismiss
    @State private var customPrefix = ""
    @State private var isCustomPrefixSelected = false
    @State private var originalPrefix = ""
    
    private let defaultPrefixes = [
        "⏱️",
        "📅",
        "🕐",
        "⏰",
        "TIME",
        "TRACK",
        "[TIME]",
        "[TRACK]"
    ]
    
    var body: some View {
        NavigationView {
            List {
                Section("Пользовательский префикс") {
                    TextField("Введите префикс", text: $customPrefix)
                        .onChange(of: customPrefix) { _, newValue in
                            if !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                selectedPrefix = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
                                isCustomPrefixSelected = true
                            } else {
                                isCustomPrefixSelected = false
                                selectedPrefix = originalPrefix
                            }
                        }
                }
                
                Section("Предустановленные") {
                    ForEach(defaultPrefixes, id: \.self) { prefix in
                        Button(action: {
                            selectedPrefix = prefix
                            isCustomPrefixSelected = false
                            customPrefix = ""
                            dismiss()
                        }) {
                            HStack {
                                Text(prefix)
                                    .font(.title2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if selectedPrefix == prefix && !isCustomPrefixSelected {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Выберите префикс")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Сохраняем исходный префикс
                originalPrefix = selectedPrefix
                
                // Инициализируем поле пользовательского префикса
                if !defaultPrefixes.contains(selectedPrefix) {
                    customPrefix = selectedPrefix
                    isCustomPrefixSelected = true
                }
            }
        }
    }
}

#Preview {
    SettingsView()
} 
