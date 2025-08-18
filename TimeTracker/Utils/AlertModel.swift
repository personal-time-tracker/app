//
//  AlertModel.swift
//  TimeTracker
//
//  Created by Илья on 03.08.2025.
//


//
//  Alert.swift
//  TimeTracker
//
//  Created by Илья on 30.07.2025.
//

import Foundation
import SwiftUI
import OSLog

struct AlertModel: Identifiable {
    
    let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TimeTracker", category: "AlertModel")
    
    init(
        title: String = "Произошла ошибка",
        error: Error,
        buttonText: String = "ОК",
        callback: @escaping () -> Void = {}
    ) {
        
        var message = ""
        if var existing = error as? AppError {
            message = existing.humanText
            message = message + "\n\n" + existing.developerText
        } else {
            logger.error("Ошибка не обернута")
            message = ""
        }
        
        self.message = message
        self.title = title
        self.buttonText = buttonText
        self.callback = callback
        
        logger.info("""
        [ALERT]
        Title: \(title)
        Message: \(message)
        ButtonText: \(buttonText)
        """)
    }
    
    init(
        title: String,
        message: String,
        buttonText: String = "ОК",
        callback: @escaping () -> Void = {}
    ) {
        self.title = title
        self.message = message
        self.buttonText = buttonText
        self.callback = callback
    }
    
    let id = UUID()
    let title: String
    let message: String
    let buttonText: String
    let callback: () -> Void
    
    var asAlert: Alert {
        Alert(
            title: Text(title),
            message: Text(message),
            dismissButton: .cancel(Text(buttonText), action: callback)
        )
    }
}
