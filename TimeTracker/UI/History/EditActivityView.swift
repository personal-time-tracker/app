import SwiftUI

struct EditActivityView: View {
    
    @Environment(\.dismiss) var dismiss
    
    @State private var vm: EditActivityViewModel
    
    init(activity: TimeActivity) {
        _vm = State(initialValue: EditActivityViewModel(activity: activity, mode: .update))
    }
    
    var body: some View {
        Form {
            Section("Название") {
                TextField("Название", text: $vm.currentActivity.title)
            }
            
            Section("Календарь") {
                Picker("Календарь", selection: $vm.currentActivity.calendarId) {
                    ForEach(vm.calendars) { calendar in
                        Text(calendar.title.replacingOccurrences(of: "⏱️ ", with: "")).tag(calendar.id)
                    }
                }
            }
            
            Section("Время") {
                DatePicker("Начало", selection: $vm.currentActivity.startTime, displayedComponents: [.hourAndMinute, .date])
                DatePicker("Окончание", selection: $vm.currentActivity.endTime, displayedComponents: [.hourAndMinute, .date])
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
    }
} 