import SwiftUI
import Factory

struct ActivitySelectionView: View {
    
    @ObservationIgnored
    @Injected(\.calendarService) private var calendarService
    
    @AppStorage("calendarPrefix") private var calendarPrefix = "⏱️"
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var activityTitle = ""
    @State private var selectedCalendarId = ""
    @State private var showingCalendarPicker = false
    
    var body: some View {
        Form {
                
            Section {
                TextField("Название занятия", text: $activityTitle)
            }

            // Выбор календаря
            Section(
                footer:
                    Text("Доступны только календари с префиксом \"\(calendarPrefix)\" в названии")
            ) {
                
                Picker(
                    "Календарь",
                    selection: $selectedCalendarId
                ) {
                    ForEach(calendarService.calendars) { calendar in
                        Text(calendar.title)
                    }
                }
            }
                            
            // Кнопка начала
            Button(action: startActivity) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Начать занятие")
                }
                .font(.headline)
                .cornerRadius(12)
            }
            .disabled(!canStartActivity)
        }
        .navigationTitle("Новое занятие")
    }
    
    private var canStartActivity: Bool {
        !activityTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !selectedCalendarId.isEmpty
    }
    
    private func startActivity() {
        let trimmedTitle = activityTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        calendarService.startNewSession(title: trimmedTitle, calendarId: selectedCalendarId)
        dismiss()
    }
}

#Preview {
    ActivitySelectionView()
} 
