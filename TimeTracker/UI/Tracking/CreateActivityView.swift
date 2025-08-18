import SwiftUI
import Factory

struct CreateActivityView: View {
    
    @State private var vm = CreateActivityViewModel()
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTitleFieldFocused: Bool
    @State private var isSuggestionsExpanded = false
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Название занятия", text: $vm.activityTitle)
                        .focused($isTitleFieldFocused)
                        .onChange(of: vm.activityTitle) { _, _ in
                            // Сворачиваем список при начале ввода
                            if !vm.activityTitle.isEmpty {
                                isSuggestionsExpanded = false
                            }
                        }
                    
                    let suggestions = vm.filteredActivities
                    let limit = 3
                    
                    if !suggestions.isEmpty {
                        ForEach(suggestions.prefix(isSuggestionsExpanded ? suggestions.count : limit)) { activity in
                            Button(action: {
                                vm.selectSuggestion(activity)
                            }) {
                                HStack {
                                    Text(activity.title)
                                    Spacer()
                                    Text(activity.calendarName.replacingOccurrences(of: vm.calendarPrefix, with: "").trimmingCharacters(in: .whitespaces))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .foregroundColor(.primary)
                        }
                        
                        if suggestions.count > limit {
                            Button(isSuggestionsExpanded ? "Свернуть" : "Показать еще \(suggestions.count - limit)") {
                                withAnimation {
                                    isSuggestionsExpanded.toggle()
                                }
                            }
                        }
                    }
                }
                
                // Выбор календаря
                Section(
                    footer:
                        Text("Доступны только календари с префиксом \"\(vm.calendarPrefix)\" в названии")
                ) {
                    Menu {
                        Picker("Календарь", selection: $vm.selectedCalendarId) {
                            ForEach(vm.calendars) { calendar in
                                Text(calendar.title).tag(calendar.id)
                            }
                        }
                        
                        Divider()
                        
                        Button(action: { vm.showingCreateCalendarSheet = true }) {
                            Label("Создать календарь", systemImage: "plus.circle.fill")
                        }
                    } label: {
                        HStack {
                            Text("Календарь")
                            Spacer()
                            Text(selectedCalendarTitle)
                                .foregroundColor(vm.selectedCalendarId.isEmpty ? .secondary : .accentColor)
                        }
                        .contentShape(Rectangle()) // Увеличиваем область нажатия
                    }
                }
                
                Section(header: Text("Время начала")) {
                    DatePicker(
                        "Начало",
                        selection: $vm.startTime,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    
                    if vm.lastFinishedActivity != nil {
                        Button("Начать после предыдущей") {
                            vm.setStartTimeFromPrevious()
                        }
                    }
                }
                
                // Выбор продолжительности
                Section(header: Text("Планируемая продолжительность")) {
                    DurationPickerView(
                        hours: $vm.hours,
                        minutes: $vm.minutes,
                    )
                    .frame(height: 150) // Ограничиваем высоту, чтобы выглядело аккуратно
                }
                
                // Кнопка начала
                Button(action: {
                    do {
                        try vm.startActivity()
                        dismiss()
                    } catch {
                        
                    }
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Начать занятие")
                    }
                    .font(.headline)
                    .cornerRadius(12)
                }
                .disabled(!vm.canStartActivity)
            }
            .navigationTitle("Новое занятие")
            .toolbar {
                ToolbarItem {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $vm.showingCreateCalendarSheet) {
                NavigationStack {
                    CreateCalendarView()
                }
            }
            .onAppear {
                vm.refreshCalendarsIfNeeded()
                isTitleFieldFocused = true
            }
            .alert(item: $vm.alert) { $0.asAlert }
        }
    }
    
    private var selectedCalendarTitle: String {
        if let calendar = vm.calendars.first(where: { $0.id == vm.selectedCalendarId }) {
            return calendar.title.replacingOccurrences(of: vm.calendarPrefix, with: "").trimmingCharacters(in: .whitespaces)
        } else {
            return "Выберите"
        }
    }
}

#Preview {
    CreateActivityView()
} 
