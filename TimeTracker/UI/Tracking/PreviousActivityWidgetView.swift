import SwiftUI

struct PreviousActivityWidgetView: View {
    
    var previousActivity: TimeActivity?
    var namespace: Namespace.ID
    
    @State private var vm = PreviousActivityWidgetViewModel()

    var body: some View {
        // Показываем виджет только если есть последняя завершенная сессия
        if let session = previousActivity {
            VStack(alignment: .leading, spacing: 16) {
                // Заголовок
                HStack {
                    Image(systemName: "arrow.backward.circle.fill")
                        .foregroundColor(.secondary)
                    Text("Последнее занятие")
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    NavigationLink(value: TrackingTabListRoute.editActivity(session)) {
                        ActivityCardView(
                            activity: session,
                            progress: 1.0, // Для предыдущей всегда полная
                            progressColor: .red,
                            leftLabel: "",
                            rightLabel: vm.timeSinceEndedString(for: session)
                        )
                    }
                    .buttonStyle(.plain)
                    .matchedGeometryEffect(id: session.id, in: namespace)
                    
                    // Кнопки для продления и завершения
                    VStack(spacing: 10) {
                        
                        Text("Продолжить и добавить время:")
                            .font(.caption)
                        
                        HStack(spacing: 10) {
                            Button("+5 мин") {
                                vm.extendSession(eventId: session.id, by: 300)
                            }
                            .buttonStyle(ExtensionButtonStyle())
                            
                            Button("+15 мин") {
                                vm.extendSession(eventId: session.id, by: 900)
                            }
                            .buttonStyle(ExtensionButtonStyle())
                            
                            Button("+30 мин") {
                                vm.extendSession(eventId: session.id, by: 1800)
                            }
                            .buttonStyle(ExtensionButtonStyle())
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        
                        Button(action: {
                            vm.finishSessionNow(eventId: session.id)
                        }) {
                            Label("Завершил только сейчас", systemImage: "mappin.and.ellipse")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(10)
                                .background(Color.red.opacity(0.15))
                                .foregroundColor(.red)
                                .cornerRadius(10)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
        }
    }
}

// Стиль для кнопок
struct ExtensionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.semibold)
            .frame(maxWidth: .infinity)
            .padding(10)
            .background(Color.accentColor.opacity(0.15))
            .foregroundColor(Color.accentColor)
            .cornerRadius(10)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
}

// Preview
struct PreviousActivityWidget_Previews: PreviewProvider {
    static var previews: some View {
        @Namespace var namespace
        return PreviousActivityWidgetView(
            previousActivity: TimeActivity(
                id: UUID().uuidString,
                title: "Прошлый проект",
                calendarId: "1",
                calendarName: "Работа",
                startTime: Date().addingTimeInterval(-7200),
                endTime: Date().addingTimeInterval(-3600),
                category: "Работа"
            ),
            namespace: namespace
        )
            .padding()
            .background(Color(.systemGroupedBackground))
    }
} 
