import Foundation
import OSLog
import ActivityKit

private let liveActivityLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TimeTracker", category: "LiveActivity")

extension CalendarService {
	@MainActor
	func syncLiveActivity() async {
		guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
		
		if let currentActivity = currentActivity {
			await startOrUpdateLiveActivity(with: currentActivity)
		} else {
			await endLiveActivities()
		}
	}

	@MainActor
	private func startOrUpdateLiveActivity(with activity: TimeActivity) async {
		let attributes = TimeTrackerLiveActivityAttributes(calendarName: activity.calendarName)
		let state = TimeTrackerLiveActivityAttributes.ContentState(
			activityId: activity.id,
			title: activity.title,
			startDate: activity.startTime,
			endDate: activity.endTime
		)
		
		// Найти существующую live activity этой сессии
		if let existing = Activity<TimeTrackerLiveActivityAttributes>.activities.first(where: { $0.content.state.activityId == activity.id }) {
			self.currentLiveActivity = existing
			self.currentLiveActivityId = activity.id
			await existing.update(.init(state: state, staleDate: activity.endTime, relevanceScore: 100))
			return
		}
		
		do {
			let requested = try Activity<TimeTrackerLiveActivityAttributes>.request(
				attributes: attributes,
				content: .init(state: state, staleDate: activity.endTime),
				pushType: nil
			)
			self.currentLiveActivity = requested
			self.currentLiveActivityId = activity.id
		} catch {
			liveActivityLogger.error("Failed to request Live Activity: \(error.localizedDescription)")
		}
	}

	@MainActor
	func endLiveActivities() async {
		for activity in Activity<TimeTrackerLiveActivityAttributes>.activities {
			let state = activity.content.state
			await activity.end(.init(state: state, staleDate: nil), dismissalPolicy: .default)
		}
		self.currentLiveActivity = nil
		self.currentLiveActivityId = nil
	}
}

