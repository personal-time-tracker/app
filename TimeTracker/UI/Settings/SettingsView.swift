import SwiftUI

struct SettingsView: View {

    @Environment(\.dismiss) private var dismiss
    @State private var showingPrefixPicker = false
    
    @AppStorage("calendarPrefix") var calendarPrefix: String = "⏱️"
    @AppStorage("selectedTheme") private var selectedTheme: Theme = .system
    
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
