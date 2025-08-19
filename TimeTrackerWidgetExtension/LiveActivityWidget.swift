import SwiftUI
import WidgetKit
import ActivityKit
import Foundation

struct TimeTrackerLiveActivityWidget: Widget {
	var body: some WidgetConfiguration {
		ActivityConfiguration(for: TimeTrackerLiveActivityAttributes.self) { context in
			LockScreenContent(context: context)
				.padding()
				.activityBackgroundTint(Color(.systemBackground))
				.activitySystemActionForegroundColor(.blue)
		} dynamicIsland: { context in
			DynamicIsland {
				DynamicIslandExpandedRegion(.leading) {
					CountdownRing(startDate: context.state.startDate, endDate: context.state.endDate, lineWidth: 3)
						.frame(width: 18, height: 18)
						.padding(.leading, 4)
				}
				DynamicIslandExpandedRegion(.trailing) {
					EmptyView()
				}
				DynamicIslandExpandedRegion(.center) {
					VStack(spacing: 4) {
						Text(context.state.title)
							.font(.subheadline)
							.lineLimit(1)
							.minimumScaleFactor(0.8)
							.multilineTextAlignment(.center)
						Text(timerInterval: context.state.startDate...context.state.endDate, countsDown: true)
							.font(.caption.monospacedDigit())
							.foregroundColor(.blue)
							.padding(.horizontal, 8)
							.padding(.vertical, 2)
							.background(Color.blue.opacity(0.1))
							.cornerRadius(6)
					}
					.frame(maxWidth: .infinity, alignment: .center)
				}
				DynamicIslandExpandedRegion(.bottom) {
					Text(context.attributes.calendarName.replacingOccurrences(of: "⏱️ ", with: ""))
						.font(.caption)
						.lineLimit(1)
						.minimumScaleFactor(0.7)
						.frame(maxWidth: .infinity, alignment: .center)
				}
			} compactLeading: {
				CountdownRing(startDate: context.state.startDate, endDate: context.state.endDate, lineWidth: 3)
					.frame(width: 20, height: 20)
					.padding(.trailing, 2)
			} compactTrailing: {
				Text("")
			} minimal: {
				CountdownRing(startDate: context.state.startDate, endDate: context.state.endDate, lineWidth: 3)
					.frame(width: 16, height: 16)
			}
			.widgetURL(URL(string: "timetracker://current"))
			.keylineTint(.blue)
		}
	}
}

private struct LockScreenContent: View {
	let context: ActivityViewContext<TimeTrackerLiveActivityAttributes>
	
	var body: some View {
		VStack(alignment: .leading, spacing: 12) {
			VStack(alignment: .leading) {
				HStack {
					Text(context.state.title)
						.font(.headline)
						.fontWeight(.semibold)
					Spacer()
					Text(formatDuration(context.state.endDate.timeIntervalSince(context.state.startDate)))
						.font(.caption)
						.fontWeight(.medium)
						.foregroundColor(.blue)
						.padding(.horizontal, 8)
						.padding(.vertical, 4)
						.background(Color.blue.opacity(0.1))
						.cornerRadius(8)
				}
				Text("\(formatTime(context.state.startDate)) - \(formatTime(context.state.endDate))")
					.font(.subheadline)
					.foregroundColor(.secondary)
			}
			
			// Прогресс
			TimelineView(.periodic(from: .now, by: 1)) { timeline in
				let now = timeline.date
				let progress = progressFraction(start: context.state.startDate, end: context.state.endDate, now: now)
				VStack(spacing: 4) {
					ProgressView(value: progress)
						.tint(.blue)
					HStack {
						Text(elapsedTimeString(since: context.state.startDate, now: now))
						Spacer()
						Text(remainingTimeString(from: now, to: context.state.endDate))
					}
					.font(.caption)
					.foregroundColor(.secondary)
				}
			}
			
			// Календарь
			HStack {
				Image(systemName: "calendar")
					.foregroundColor(.secondary)
				Text(context.attributes.calendarName.replacingOccurrences(of: "⏱️ ", with: ""))
					.font(.subheadline)
					.foregroundColor(.secondary)
				Spacer()
			}
		}
	}
}

private struct CountdownRing: View {
	let startDate: Date
	let endDate: Date
	let lineWidth: CGFloat
	
	var body: some View {
		TimelineView(.periodic(from: .now, by: 1)) { timeline in
			let now = timeline.date
			let remainingFraction = max(0, 1 - progressFraction(start: startDate, end: endDate, now: now))
			ZStack {
				Circle()
					.stroke(Color.secondary.opacity(0.2), lineWidth: lineWidth)
				Circle()
					.trim(from: 0, to: CGFloat(remainingFraction))
					.stroke(Color.blue, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
					.rotationEffect(.degrees(-90))
			}
		}
	}
}


// Форматирует продолжительность как часы:минуты:секунды (01:23:45) или минуты:секунды (12:34)
func formatDurationClock(_ duration: TimeInterval) -> String {
    let total = Int(max(0, duration))
    let hours = total / 3600
    let minutes = (total % 3600) / 60
    let seconds = total % 60
    if hours > 0 {
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    } else {
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Helpers (Widget-only)

private func progressFraction(start: Date, end: Date, now: Date) -> Double {
	let total = end.timeIntervalSince(start)
	guard total > 0 else { return 1 }
	let elapsed = now.timeIntervalSince(start)
	return min(max(elapsed / total, 0), 1)
}

private func elapsedTimeString(since start: Date, now: Date) -> String {
	let elapsed = max(0, now.timeIntervalSince(start))
	return formatDuration(elapsed)
}

private func remainingTimeString(from now: Date, to end: Date) -> String {
	let remaining = max(0, end.timeIntervalSince(now))
	return formatDuration(remaining)
}

