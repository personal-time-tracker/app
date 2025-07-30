//
//  CalendarInfo.swift
//  TImeTracker
//
//  Created by Илья on 28.07.2025.
//

import SwiftUI

struct CalendarInfo: Identifiable {
    let id: String
    var title: String
    let color: CGColor
    
    init(
        id: String = "",
        title: String = "",
        color: CGColor = .init(genericCMYKCyan: 1, magenta: 0, yellow: 0, black: 0, alpha: 1)
    ) {
        self.id = id
        self.title = title
        self.color = color
    }
    
    func convertToCreateCalendar() -> CreateCalendar {
        CreateCalendar(
            title: title,
            color: color
        )
    }
}

struct CreateCalendar {
    var title: String
    let color: CGColor
}

struct UpdateCalendar {
    let id: String
    let title: String?
    let color: CGColor?
}
