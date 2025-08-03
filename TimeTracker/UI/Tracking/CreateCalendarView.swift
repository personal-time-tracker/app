import SwiftUI

struct CreateCalendarView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var vm = CreateCalendarViewModel()
    
    var body: some View {
        NavigationView {
            Form {
                Section(
                    header: Text("Название календаря"),
                    footer: Text("Префикс \"\(vm.calendarPrefix)\" будет добавлен автоматически.")
                ) {
                    TextField("Название", text: $vm.calendarTitle)
                }
                
                Section {
                    Button(action: {
                        vm.createCalendar()
                        dismiss()
                    }) {
                        Text("Создать")
                    }
                    .disabled(!vm.isTitleValid)
                }
            }
            .navigationTitle("Новый календарь")
            .navigationBarItems(leading: Button("Отмена", action: { dismiss() }))
            .alert(item: $vm.alert) { $0.asAlert }
        }
    }
} 
