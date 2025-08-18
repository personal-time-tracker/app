import SwiftUI

struct EditActivityView: View {
    
    @Environment(\.dismiss) var dismiss
    
    @State private var vm: EditActivityViewModel
    
    init(activity: TimeActivity) {
        _vm = State(initialValue: EditActivityViewModel(activity: activity, mode: .update))
    }
    
    var body: some View {
        if let activity = vm.currentActivity {
            Form {
                Section("Название") {
                    TextField("Название", text:Binding(
                        get: { activity.title },
                        set: { vm.currentActivity?.title = $0 }
                    ))
                }
                
                Section("Календарь") {
                    Picker("Календарь", selection: Binding(
                        get: { activity.calendarId },
                        set: { vm.currentActivity?.calendarId = $0 }
                    )) {
                        ForEach(vm.calendars) { calendar in
                            Text(calendar.title.replacingOccurrences(of: "⏱️ ", with: "")).tag(calendar.id)
                        }
                    }
                }
                
                Section("Время") {
                    DatePicker("Начало", selection: Binding(
                        get: { activity.startTime },
                        set: { vm.currentActivity?.startTime = $0 }
                    ), displayedComponents: [.hourAndMinute, .date])
                    DatePicker("Окончание", selection: Binding(
                        get: { activity.endTime },
                        set: { vm.currentActivity?.endTime = $0 }
                    ), displayedComponents: [.hourAndMinute, .date])
                }
                
                Section {
                    Button("Сохранить") {
                        vm.save()
                        dismiss()
                    }
                }
                
                Section {
                    Button("Удалить", role: .destructive) {
                        vm.delete()
                        dismiss()
                    }
                }
            }
            .navigationTitle("Изменить активность")
            .navigationBarTitleDisplayMode(.inline)
            .alert(item: $vm.alert) { $0.asAlert }
        } else {
            ProgressView()
                .navigationTitle("Загрузка...")
        }
    }
}
