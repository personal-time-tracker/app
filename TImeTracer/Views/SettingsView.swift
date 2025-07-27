import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingPrefixPicker = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Префикс календарей") {
                    Text("Приложение будет работать только с календарями, содержащими выбранный префикс в названии")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("Текущий префикс")
                        Spacer()
                        Button(settings.calendarPrefix) {
                            showingPrefixPicker = true
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                Section("Примеры") {
                    Text("С префиксом \"\(settings.calendarPrefix)\" будут учитываться календари с любым из следующих форматов:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(settings.calendarPrefix) Работа")
                    Text("Учеба \(settings.calendarPrefix)") 
                    Text("Тайм \(settings.calendarPrefix) Менеджмент")
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
                PrefixPickerView(selectedPrefix: $settings.calendarPrefix)
            }
        }
    }
}

struct PrefixPickerView: View {
    @Binding var selectedPrefix: String
    @Environment(\.dismiss) private var dismiss
    @State private var customPrefix = ""
    @State private var isCustomPrefixSelected = false
    @State private var originalPrefix = ""
    
    var body: some View {
        NavigationView {
            List {
                Section("Пользовательский префикс") {
                    TextField("Введите префикс", text: $customPrefix)
                        .onChange(of: customPrefix) { newValue in
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
                    ForEach(AppSettings.defaultPrefixes, id: \.self) { prefix in
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
                if !AppSettings.defaultPrefixes.contains(selectedPrefix) {
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