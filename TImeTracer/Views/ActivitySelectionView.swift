import SwiftUI

struct ActivitySelectionView: View {
    @ObservedObject var calendarService: CalendarService
    @Environment(\.dismiss) private var dismiss
    
    @State private var activityTitle = ""
    @State private var selectedCalendarId = ""
    @State private var showingCalendarPicker = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Название занятия
                VStack(alignment: .leading, spacing: 8) {
                    Text("Название занятия")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("Например: Работа, Учеба, Спорт...", text: $activityTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.body)
                }
                
                // Выбор календаря
                VStack(alignment: .leading, spacing: 8) {
                    Text("Календарь")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Button(action: {
                        showingCalendarPicker = true
                    }) {
                        HStack {
                            if let selectedCalendar = calendarService.calendars.first(where: { $0.id == selectedCalendarId }) {
                                Text(selectedCalendar.title)
                                    .foregroundColor(.primary)
                            } else {
                                Text("Выберите календарь")
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                
                Spacer()
                
                // Кнопка начала
                Button(action: startActivity) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Начать занятие")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canStartActivity ? Color.blue : Color.gray)
                    .cornerRadius(12)
                }
                .disabled(!canStartActivity)
            }
            .padding()
            .navigationTitle("Новое занятие")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCalendarPicker) {
                CalendarPickerView(
                    calendars: calendarService.calendars,
                    selectedCalendarId: $selectedCalendarId
                )
            }
        }
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

struct CalendarPickerView: View {
    let calendars: [CalendarInfo]
    @Binding var selectedCalendarId: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(calendars) { calendar in
                Button(action: {
                    selectedCalendarId = calendar.id
                    dismiss()
                }) {
                    HStack {
                        Circle()
                            .fill(Color(calendar.color))
                            .frame(width: 12, height: 12)
                        
                        Text(calendar.title)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        if selectedCalendarId == calendar.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Выберите календарь")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Отмена") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ActivitySelectionView(calendarService: CalendarService())
} 