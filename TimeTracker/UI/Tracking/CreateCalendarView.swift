import SwiftUI
import Factory

struct CreateCalendarView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var vm: CreateCalendarViewModel
    
    init() {
        vm = CreateCalendarViewModel(currentCalendar: CalendarInfo())
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(
                    header: Text("Название календаря"),
                    footer: Text("Префикс \"\(vm.calendarPrefix)\" будет добавлен автоматически.")
                ) {
                    TextField("Название", text: $vm.currentCalendar.title)
                }
                
                Section {
                    Button(action: {
                        vm.createCalendar()
                        dismiss()
                    }) {
                        Text("Создать")
                    }
                    .disabled(!vm.isDisableSaveButton)
                }
            }
            .navigationTitle("Новый календарь")
            .navigationBarItems(leading: Button("Отмена", action: { dismiss() }))
            .alert(item: $vm.alert) { $0.asAlert }
        }
    }
} 
