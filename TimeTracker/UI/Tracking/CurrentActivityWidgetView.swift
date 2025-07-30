import SwiftUI

struct CurrentActivityWidgetView: View {
    
    @Bindable var vm: TrackingViewModel
    var namespace: Namespace.ID
    
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
            if let currentActivity = vm.currentActivity {
                NavigationLink(value: TrackingTabListRoute.editActivity(currentActivity)) {
                    ActivityCardView(
                        activity: currentActivity,
                        progress: vm.progress(for: currentActivity),
                        progressColor: .blue,
                        leftLabel: vm.elapsedTimeString(for: currentActivity),
                        rightLabel: vm.remainingTimeString(for: currentActivity),
                        onTimeAdjustment: { timeInterval in
                            vm.extendCurrentActivity(by: timeInterval)
                        }
                    )
                }
                .buttonStyle(.plain)
                .matchedGeometryEffect(id: currentActivity.id, in: namespace)
                
                // Кнопка действия
                HStack(spacing: 8) {
                    Button {
                        vm.isShowNewSessionSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.triangle.2.circlepath")
                            Text("Сменить")
                        }
                        .fontWeight(.medium)
                        .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button {
                        vm.finishCurrentActivityNow()
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
                
            } else {
                Button {
                    vm.isShowNewSessionSheet = true
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
            vm: TrackingViewModel(),
            namespace: _namespace.wrappedValue
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
            vm: TrackingViewModel(),
            namespace: _namespace.wrappedValue
        )
        Spacer()
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
