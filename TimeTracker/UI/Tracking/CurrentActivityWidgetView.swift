import SwiftUI

struct CurrentActivityWidgetView: View {
    
    @State private var vm = CurrentActivityWidgetViewModel()
    @State private var isShowingTimePopover = false
    var namespace: Namespace.ID
        
    var currentActivity: TimeActivity?
    @Binding var isShowNewSessionSheet: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // Заголовок
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundColor(.blue)
                Text("Сейчас занимаюсь")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            // Текущее занятие
            if let activity = currentActivity {
                NavigationLink(value: TrackingTabListRoute.editActivity(activity)) {
                    ActivityCardView(
                        activity: activity,
                        progress: vm.progress(for: activity),
                        progressColor: .blue,
                        leftLabel: vm.elapsedTimeString(for: activity),
                        rightLabel: vm.remainingTimeString(for: activity),
                        onTimeAdjustment: { timeInterval in
                            vm.updateEndTime(for: activity, by: timeInterval)
                        }
                    )
                }
                .buttonStyle(.plain)
                .matchedGeometryEffect(id: activity.id, in: namespace)
                
                // Кнопка действия
                HStack(spacing: 8) {
                    Button {
                        isShowNewSessionSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Сменить")
                        }
                        .fontWeight(.medium)
                        .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    if let currentActivity {
                        Button {
                            vm.finishSessionNow(eventId: currentActivity.id)
                        } label: {
                            HStack {
                                Image(systemName: "stop.fill")
                                Text("Завершить")
                            }
                            .fontWeight(.medium)
                            .padding()
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                }
                
            } else {
                Button {
                    isShowNewSessionSheet = true
                } label: {
                    VStack(spacing: 8) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        Text("Начать занятие")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }
}

#Preview("With data") {
    @Previewable @Namespace var namespace
    VStack {
        CurrentActivityWidgetView(
            namespace: _namespace.wrappedValue,
            currentActivity: TimeActivity(
                id: UUID().uuidString,
                title: "Занятие",
                calendarId: UUID().uuidString,
                calendarName: "⏱️ Работа",
                startTime: Date.now.addingTimeInterval(-3600),
                endTime: Date.now,
                category: nil
            ),
            isShowNewSessionSheet: .constant(true)
        )
        Spacer()
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Without data") {
    @Previewable @Namespace var namespace
    VStack {
        CurrentActivityWidgetView(
            namespace: _namespace.wrappedValue,
            currentActivity: nil,
            isShowNewSessionSheet: .constant(true)
        )
        Spacer()
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
