import SwiftUI
import WidgetKit
import ActivityKit

struct TimeTrackerLiveActivityWidget: Widget {
	var body: some WidgetConfiguration {
		ActivityConfiguration(for: TimeTrackerLiveActivityAttributes.self) { context in
			VStack(alignment: .leading, spacing: 8) {
				HStack {
					Image(systemName: "clock.fill")
						.foregroundColor(.blue)
					Text(context.attributes.calendarName)
						.font(.caption)
						.foregroundColor(.secondary)
					Spacer()
				}
				Text(context.state.title)
					.font(.headline)
					.fontWeight(.semibold)
				
				// Отсчет до окончания
				Text(timerInterval: context.state.startDate...context.state.endDate, countsDown: true)
					.font(.caption)
					.foregroundColor(.blue)
			}
			.padding()
			.activityBackgroundTint(Color(.systemBackground))
			.activitySystemActionForegroundColor(.blue)
		} dynamicIsland: { context in
			DynamicIsland {
				DynamicIslandExpandedRegion(.leading) {
					Image(systemName: "clock.fill")
				}
				DynamicIslandExpandedRegion(.trailing) {
					Text(context.attributes.calendarName)
						.font(.caption2)
				}
				DynamicIslandExpandedRegion(.center) {
					VStack(alignment: .leading) {
						Text(context.state.title)
							.font(.subheadline)
						Text(timerInterval: context.state.startDate...context.state.endDate, countsDown: true)
							.font(.caption)
							.foregroundColor(.blue)
					}
				}
			} compactLeading: {
				Image(systemName: "clock.fill")
			} compactTrailing: {
				Text(timerInterval: context.state.startDate...context.state.endDate, countsDown: true)
					.font(.caption2)
			} minimal: {
				Image(systemName: "clock.fill")
			}
			.widgetURL(URL(string: "timetracker://current"))
			.keylineTint(.blue)
		}
	}
}

