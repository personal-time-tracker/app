import SwiftUI
import Factory

struct CreateActivityView: View {
    
    @State private var vm = CreateActivityViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
                
            Section {
                TextField("Название занятия", text: $vm.activityTitle)
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
                vm.startActivity()
                dismiss()
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
        .sheet(isPresented: $vm.showingCreateCalendarSheet) {
            CreateCalendarView()
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
