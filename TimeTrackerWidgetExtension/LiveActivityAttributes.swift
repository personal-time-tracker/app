import Foundation
import ActivityKit

struct TimeTrackerLiveActivityAttributes: ActivityAttributes {
	struct ContentState: Codable, Hashable {
		var activityId: String
		var title: String
		var startDate: Date
		var endDate: Date
	}

	var calendarName: String
}

