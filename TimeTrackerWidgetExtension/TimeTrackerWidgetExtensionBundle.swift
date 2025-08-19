//
//  TimeTracerWidgetExtensionBundle.swift
//  TimeTracerWidgetExtension
//
//  Created by Илья on 27.07.2025.
//

import WidgetKit
import SwiftUI

@main
struct TimeTracerWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        TimeTracerWidget()
        TimeTrackerLiveActivityWidget()
    }
}
