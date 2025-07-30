import SwiftUI

struct PreviousActivityWidgetView: View {
    
    var namespace: Namespace.ID
    @Bindable var vm: TrackingViewModel
    
    var body: some View {
        if vm.currentActivity == nil {
            if let previousActivity = vm.previousActivity {
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
                        NavigationLink(value: TrackingTabListRoute.editActivity(previousActivity)) {
                            ActivityCardView(
                                activity: previousActivity,
                                progress: 1.0, // Для предыдущей всегда полная
                                progressColor: .red,
                                leftLabel: "",
                                rightLabel: vm.timeSinceEndedString(for: previousActivity)
                            )
                        }
                        .buttonStyle(.plain)
                        .matchedGeometryEffect(id: previousActivity.id, in: namespace)
                        
                        // Кнопки для продления и завершения
                        VStack(spacing: 10) {
                            
                            Text("Продолжить и добавить время:")
                            
                            HStack(spacing: 10) {
                                
                                ForEach(vm.continueEndExtendActivitySuggestions, id: \.self) { suggestionAdjustment in
                                    Button(formatTimeAdjustment(suggestionAdjustment)) {
                                        vm.continueAndExtendPreviousActivity(by: suggestionAdjustment)
                                    }
                                    .buttonStyle(ExtensionButtonStyle())
                                }
                            }
                            .fixedSize(horizontal: false, vertical: true)
                            
                            Button(action: {
                                vm.continueAndExtendPreviousActivity(by: 0)
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
                .transition(.opacity)
            }
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
#Preview {
    
    @Previewable @Namespace var namespace
    let vm = TrackingViewModel()
    // Manually set a previous activity for preview
    let previewActivity = Activity(
        id: UUID().uuidString,
        title: "Прошлый проект",
        calendarId: "1",
        calendarName: "Работа",
        startTime: Date().addingTimeInterval(-7200),
        endTime: Date().addingTimeInterval(-3600)
    )
    
    PreviousActivityWidgetView(
        namespace: namespace,
        vm: vm
    )
        .padding()
        .background(Color(.systemGroupedBackground))
}
