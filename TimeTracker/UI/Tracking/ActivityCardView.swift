import SwiftUI

struct ActivityCardView: View {
    let activity: Activity
    
    // Данные, которые передаются "сверху"
    let progress: Double
    let progressColor: Color
    let leftLabel: String
    let rightLabel: String
    
    // Опциональный обработчик для поповера
    var onTimeAdjustment: ((TimeInterval) -> Void)? = nil
    
    @State private var isShowingTimePopover = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Информация о занятии
            VStack(alignment: .leading) {
                HStack {
                    Text(activity.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    if onTimeAdjustment != nil {
                        // Если обработчик есть, делаем кнопкой
                        Button(action: { isShowingTimePopover = true }) {
                            durationLabel
                        }
                        .popover(isPresented: $isShowingTimePopover) {
                            timeAdjustmentPopover
                        }
                    } else {
                        // Иначе просто текст
                        durationLabel
                    }
                }
                
                Text("\(formatTime(activity.startTime)) - \(formatTime(activity.endTime))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Полоса прогресса
            VStack(spacing: 4) {
                ProgressView(value: progress)
                    .tint(progressColor)
                
                HStack {
                    Text(leftLabel)

                    Spacer()

                    Text(rightLabel)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            // Календарь и длительность
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.secondary)
                Text(activity.calendarName.replacingOccurrences(of: "⏱️ ", with: ""))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // Вынес в отдельное View, чтобы не дублировать код
    private var durationLabel: some View {
        Text(formatDuration(activity.duration))
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.blue)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
    }
    
    // Поповер для изменения времени
    @ViewBuilder
    private var timeAdjustmentPopover: some View {
        VStack(spacing: 0) {
            let adjustments: [TimeInterval] = [3600, 1800, 900, -900] // +1h, +30m, +15m, -15m
            
            ForEach(adjustments, id: \.self) { interval in
                Button {
                    onTimeAdjustment?(interval)
                    isShowingTimePopover = false
                } label: {
                    Text(formatTimeAdjustment(interval))
                        .frame(maxWidth: .infinity)
                }
                .padding()
                
                if interval != adjustments.last {
                    Divider()
                }
            }
        }
        .presentationCompactAdaptation(.popover)
    }
}


