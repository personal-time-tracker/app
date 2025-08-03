import SwiftUI
import Factory

struct EditActivityView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var vm: EditActivityViewModel
    @FocusState private var isTitleFieldFocused: Bool
    
    init(activity: Activity) {
        vm = EditActivityViewModel(
            currentActivity: activity,
            oldActivity: activity,
            mode: .update
        )
    }
    
    init() {
        vm = EditActivityViewModel(
            currentActivity: Activity(
                title: "",
                calendarId: "",
                calendarName: "",
                startTime: Date.now,
                endTime: Date.now.addingTimeInterval(3600),
            ),
            mode: .create
        )
    }
    
    var body: some View {
        Form {
            Section("Название") {
                TextField("Название", text: $vm.currentActivity.title)
                    .focused($isTitleFieldFocused)

                if isTitleFieldFocused {
                    ForEach(vm.suggestionActivities) { activity in
                        Button{
                            vm.selectSuggestion(activity)
                        } label: {
                            HStack {
                                Text(activity.title)
                                Spacer()
                                Text(activity.calendarName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .foregroundColor(.primary)
                    }
                    
                    if vm.isShowExpandedButton {
                        Button(vm.isSuggestionsExpanded ? "Свернуть" : "Показать еще \(vm.totalSuggestionsCount)") {
                            withAnimation {
                                vm.isSuggestionsExpanded.toggle()
                            }
                        }
                    }
                }
            }
            
            Section("Календарь") {
                Picker("Календарь", selection: $vm.calendarID) {
                    Text("Не выбран")
                        .tag(String?(nil))
                    ForEach(vm.calendars) { calendar in
                        Text(calendar.title.replacingOccurrences(of: "⏱️ ", with: "")).tag(calendar.id)
                    }
                }
            }
            
            Section(vm.mode == .create ? "Начало" : "Время") {
                DatePicker("Начало",
                    selection: $vm.currentActivity.startTime,
                    displayedComponents: [.hourAndMinute, .date]
                )
                
                // Предложение поставить начало как конец предыдущего события
                if let lastFinishedActivity = vm.lastFinishedActivity {
                    if vm.isShowSuggestionAutoStartTime {
                        Button("Сразу после предыдущей:  \(formatTime(lastFinishedActivity.endTime))") {
                            vm.setStartTimeFromPrevious()
                        }
                    }
                }
                
                if vm.mode == .update {
                    DatePicker("Конец",
                               selection: $vm.currentActivity.endTime,
                               displayedComponents: [.hourAndMinute, .date]
                    )
                }
            }
            
            if vm.mode == .create {
                Section(
                    header: Text("Планируемая продолжительность"),
                    footer: VStack(alignment: .leading, spacing: 10) {
                        Text("Планируемое окончание: \(formatTime(vm.currentActivity.endTime))")

                        if vm.isEndTimeInPast {
                            Text("Время окончания находится в прошлом, событие не будет отображено в текущей активности")
                                .foregroundColor(.orange)
                        }
                    }
                ) {
                    DurationPickerView(
                        hours: $vm.durationHours,
                        minutes: $vm.durationMinutes,
                    )
                    .frame(height: 150) // Ограничиваем высоту, чтобы выглядело аккуратно
                }
            }
            
            Section {
                Button("Сохранить") {
                    Task {
                        do {
                            try await vm.save()
                        } catch {
                            return
                        }
                        dismiss()
                    }
                }
                .disabled(vm.isDisabledSaveButton)
            }
            
            if vm.mode == .update {
                Section {
                    Button("Удалить", role: .destructive) {
                        Task {
                            do {
                                try await vm.delete()
                            } catch {
                                return
                            }
                            dismiss()
                        }
                    }
                }
            }
        }
        .task {
            if vm.mode == .create {
                isTitleFieldFocused = true
            }
        }
        .animation(.default, value: isTitleFieldFocused)
        .animation(.default, value: vm.isShowSuggestionAutoStartTime)
        .navigationTitle("Изменить активность")
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $vm.alert) { $0.asAlert }
    }
}

#Preview("Редактирование") {
    EditActivityView(
        activity: Activity(
            title: "Title",
            calendarName: "Calendar",
            startTime: Date.now,
            endTime: Date.now.addingTimeInterval(60)
        )
    )
}

#Preview("Создание") {
    EditActivityView()
}
