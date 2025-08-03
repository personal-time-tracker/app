//
//  LogLevel.swift
//  TimeTracker
//
//  Created by Илья on 03.08.2025.
//


//
//  Error.swift
//  TimeTracker
//
//  Created by Илья on 30.07.2025.
//

import Foundation
import SwiftUI
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TimeTracker", category: "Error")

// MARK: - Log Level

enum LogLevel: Int {
    case error = 0
    case warning
    case debug
    case info
    case none
}

// MARK: - ErrorType

struct ErrorType: Equatable {
    
    let logAs: LogLevel
    
    // Создание новой ошибки
    func new(
        errorText developerText: String,
        humanText: String,
        parameters: [String: Any] = [:]
    ) -> AppError {
        let appError = AppError(
            errorType: self,
            developerText: developerText,
            humanText: humanText,
            underlyingError: nil,
            stackTrace: Thread.callStackSymbols,
            parameters: parameters
        )
        
        
        appError.log()
        
        return appError
    }
    
    // Обертка существующей ошибки
    func wrap(
        error: Error,
        humanText: String = "",
        parameters: [String: Any] = [:]
    ) -> AppError {
        
        // Кастуем ошибку и если она является нашей кастомной
        if var existing = error as? AppError {
            
            // Добавляем к ошибке параметры
            existing.parameters.merge(parameters) { (_, new) in new }
            
            return existing
        }
        
        // Создаем новую ошибку
        let appError = AppError(
            errorType: self,
            developerText: error.localizedDescription,
            humanText: humanText,
            underlyingError: error,
            stackTrace: Thread.callStackSymbols,
            parameters: parameters
        )
        
        appError.log()
        
        return appError
    }
}

// MARK: - AppError

struct AppError: LocalizedError {
    
    // Тип ошибки
    let errorType: ErrorType
    
    // Текст ошибки
    let developerText: String
    
    // Человеко-читаемый текст
    let humanText: String
    
    // Вложенная ошибка
    let underlyingError: Error?
    
    // Стек вызовов (как строки)
    let stackTrace: [String]
    
    // Дополнительные параметры (как словарь)
    var parameters: [String: Any]
            
    var description: String {
        developerText
    }
        
    func log() {
        var logString = """
        [AppError]
        Type: \(errorType)
        DeveloperText: \(developerText)
        HumanText: \(humanText)
        UnderlyingError: \(underlyingError)
        Parameters: \(parameters)
        """
        
        switch errorType.logAs {
        case .error:
            logger.error("\(logString)")
        case .warning:
            logger.warning("\(logString)")
        case .debug:
            logger.debug("\(logString)")
        case .info:
            logger.info("\(logString)")
        default:
            break
        }
    }
}

// MARK: - Error types

let InternalError = ErrorType(
    logAs: .error
)
    
let UserError = ErrorType(
    logAs: .warning
)

let NotFound = ErrorType(
    logAs: .warning
)