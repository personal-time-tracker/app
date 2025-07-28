import SwiftUI

struct CreateCalendarView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = CreateCalendarViewModel()
    
    var body: some View {
        NavigationView {
            Form {
                Section(
                    header: Text("Название календаря"),
                    footer: Text("Префикс \"\(viewModel.calendarPrefix)\" будет добавлен автоматически.")
                ) {
                    TextField("Название", text: $viewModel.calendarTitle)
                }
                
                Section {
                    Button(action: {
                        viewModel.createCalendar()
                        dismiss()
                    }) {
                        Text("Создать")
                    }
                    .disabled(!viewModel.isTitleValid)
                }
            }
            .navigationTitle("Новый календарь")
            .navigationBarItems(leading: Button("Отмена", action: { dismiss() }))
        }
    }
} 
