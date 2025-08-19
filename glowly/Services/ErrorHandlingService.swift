//
//  ErrorHandlingService.swift
//  Glowly
//
//  Service for centralized error handling and logging
//

import Foundation
import SwiftUI
import os.log

/// Protocol for error handling operations
protocol ErrorHandlingServiceProtocol {
    func logError(_ error: Error, context: String?, file: String, function: String, line: Int) async
    func handleError(_ error: Error, context: String?) async -> ErrorAction
    func showUserError(_ error: UserError) async
    func reportCrash(_ error: Error, context: String?) async
    func clearLogs() async
    var recentErrors: [ErrorLog] { get }
}

/// Implementation of error handling service
@MainActor
final class ErrorHandlingService: ErrorHandlingServiceProtocol, ObservableObject {
    
    // MARK: - Properties
    @Published var recentErrors: [ErrorLog] = []
    @Published var currentUserError: UserError?
    @Published var showingErrorAlert = false
    
    private let logger = Logger(subsystem: "com.glowly.app", category: "ErrorHandling")
    private let maxLogEntries = 100
    private var analyticsService: AnalyticsServiceProtocol?
    
    // MARK: - Initialization
    init() {
        // Analytics service will be injected if available
    }
    
    /// Set analytics service for error reporting
    func setAnalyticsService(_ service: AnalyticsServiceProtocol) {
        self.analyticsService = service
    }
    
    // MARK: - Error Logging
    
    /// Log an error with context
    func logError(
        _ error: Error,
        context: String? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) async {
        let errorLog = ErrorLog(
            error: error,
            context: context,
            file: URL(fileURLWithPath: file).lastPathComponent,
            function: function,
            line: line,
            timestamp: Date()
        )
        
        // Add to recent errors
        recentErrors.insert(errorLog, at: 0)
        
        // Maintain max log entries
        if recentErrors.count > maxLogEntries {
            recentErrors = Array(recentErrors.prefix(maxLogEntries))
        }
        
        // Log to system
        logger.error("\(errorLog.description)")
        
        // Report to analytics if available
        await analyticsService?.trackError(error, context: context)
        
        #if DEBUG
        print("🚨 Error logged: \(error.localizedDescription)")
        if let context = context {
            print("   Context: \(context)")
        }
        print("   Location: \(errorLog.file):\(errorLog.line) in \(errorLog.function)")
        #endif
    }
    
    // MARK: - Error Handling
    
    /// Handle an error and return appropriate action
    func handleError(_ error: Error, context: String? = nil) async -> ErrorAction {
        await logError(error, context: context)
        
        // Determine appropriate action based on error type
        switch error {
        case let photoError as PhotoServiceError:
            return handlePhotoServiceError(photoError)
        case let processingError as ImageProcessingError:
            return handleImageProcessingError(processingError)
        case let coreMLError as CoreMLError:
            return handleCoreMLError(coreMLError)
        case let preferencesError as PreferencesError:
            return handlePreferencesError(preferencesError)
        case let networkError as URLError:
            return handleNetworkError(networkError)
        default:
            return handleGenericError(error)
        }
    }
    
    private func handlePhotoServiceError(_ error: PhotoServiceError) -> ErrorAction {
        switch error {
        case .permissionDenied:
            return .showUserError(UserError(
                title: "Permission Required",
                message: error.localizedDescription,
                actionTitle: "Settings",
                action: .openSettings
            ))
        case .invalidImageData:
            return .showUserError(UserError(
                title: "Invalid Image",
                message: "Please select a valid image file.",
                actionTitle: "OK",
                action: .dismiss
            ))
        case .operationNotSupported:
            return .showUserError(UserError(
                title: "Not Supported",
                message: "This operation is not yet available.",
                actionTitle: "OK",
                action: .dismiss
            ))
        default:
            return .showUserError(UserError(
                title: "Photo Error",
                message: error.localizedDescription,
                actionTitle: "Try Again",
                action: .retry
            ))
        }
    }
    
    private func handleImageProcessingError(_ error: ImageProcessingError) -> ErrorAction {
        switch error {
        case .invalidImage:
            return .showUserError(UserError(
                title: "Invalid Image",
                message: "The image format is not supported or the image is corrupted.",
                actionTitle: "Select Another",
                action: .dismiss
            ))
        case .insufficientMemory:
            return .showUserError(UserError(
                title: "Memory Error",
                message: "Not enough memory to process this image. Try with a smaller image.",
                actionTitle: "OK",
                action: .dismiss
            ))
        case .operationCancelled:
            return .silent // Don't show anything for cancelled operations
        default:
            return .showUserError(UserError(
                title: "Processing Error",
                message: error.localizedDescription,
                actionTitle: "Try Again",
                action: .retry
            ))
        }
    }
    
    private func handleCoreMLError(_ error: CoreMLError) -> ErrorAction {
        switch error {
        case .modelNotLoaded:
            return .showUserError(UserError(
                title: "AI Models Loading",
                message: "Please wait for AI models to finish loading.",
                actionTitle: "OK",
                action: .dismiss
            ))
        case .insufficientMemory:
            return .showUserError(UserError(
                title: "Memory Error",
                message: "Not enough memory for AI processing. Try closing other apps.",
                actionTitle: "OK",
                action: .dismiss
            ))
        default:
            return .showUserError(UserError(
                title: "AI Processing Error",
                message: "AI enhancement is temporarily unavailable.",
                actionTitle: "Continue",
                action: .dismiss
            ))
        }
    }
    
    private func handlePreferencesError(_ error: PreferencesError) -> ErrorAction {
        return .showUserError(UserError(
            title: "Settings Error",
            message: "Failed to save your settings. They will be restored when you restart the app.",
            actionTitle: "OK",
            action: .dismiss
        ))
    }
    
    private func handleNetworkError(_ error: URLError) -> ErrorAction {
        return .showUserError(UserError(
            title: "Connection Error",
            message: "Please check your internet connection and try again.",
            actionTitle: "Retry",
            action: .retry
        ))
    }
    
    private func handleGenericError(_ error: Error) -> ErrorAction {
        return .showUserError(UserError(
            title: "Unexpected Error",
            message: "Something went wrong. Please try again.",
            actionTitle: "OK",
            action: .dismiss
        ))
    }
    
    // MARK: - User Error Display
    
    /// Show error to user with appropriate UI
    func showUserError(_ error: UserError) async {
        currentUserError = error
        showingErrorAlert = true
    }
    
    /// Dismiss current user error
    func dismissUserError() {
        currentUserError = nil
        showingErrorAlert = false
    }
    
    // MARK: - Crash Reporting
    
    /// Report a crash or critical error
    func reportCrash(_ error: Error, context: String? = nil) async {
        let crashLog = ErrorLog(
            error: error,
            context: context,
            file: "Unknown",
            function: "Unknown",
            line: 0,
            timestamp: Date(),
            severity: .critical
        )
        
        recentErrors.insert(crashLog, at: 0)
        
        logger.critical("CRASH: \(error.localizedDescription)")
        
        // Report to analytics with high priority
        await analyticsService?.trackError(error, context: "CRASH: \(context ?? "")")
        
        #if DEBUG
        print("💥 CRASH REPORTED: \(error.localizedDescription)")
        #endif
    }
    
    // MARK: - Log Management
    
    /// Clear all error logs
    func clearLogs() async {
        recentErrors.removeAll()
        logger.info("Error logs cleared")
    }
    
    /// Get errors by severity
    func getErrorsBySeverity(_ severity: ErrorSeverity) -> [ErrorLog] {
        return recentErrors.filter { $0.severity == severity }
    }
    
    /// Get recent errors count
    var recentErrorsCount: Int {
        recentErrors.count
    }
    
    /// Get critical errors count
    var criticalErrorsCount: Int {
        getErrorsBySeverity(.critical).count
    }
}

// MARK: - ErrorLog

struct ErrorLog: Identifiable {
    let id = UUID()
    let error: Error
    let context: String?
    let file: String
    let function: String
    let line: Int
    let timestamp: Date
    let severity: ErrorSeverity
    
    init(
        error: Error,
        context: String?,
        file: String,
        function: String,
        line: Int,
        timestamp: Date,
        severity: ErrorSeverity = .error
    ) {
        self.error = error
        self.context = context
        self.file = file
        self.function = function
        self.line = line
        self.timestamp = timestamp
        self.severity = severity
    }
    
    var description: String {
        var desc = "\(severity.emoji) [\(timestamp.formatted(.dateTime))] \(error.localizedDescription)"
        if let context = context {
            desc += " | Context: \(context)"
        }
        desc += " | \(file):\(line) in \(function)"
        return desc
    }
}

// MARK: - ErrorSeverity

enum ErrorSeverity: String, CaseIterable {
    case info = "info"
    case warning = "warning"
    case error = "error"
    case critical = "critical"
    
    var emoji: String {
        switch self {
        case .info:
            return "ℹ️"
        case .warning:
            return "⚠️"
        case .error:
            return "❌"
        case .critical:
            return "💥"
        }
    }
    
    var displayName: String {
        rawValue.capitalized
    }
}

// MARK: - ErrorAction

enum ErrorAction {
    case silent
    case showUserError(UserError)
    case retry
    case openSettings
    case restart
}

// MARK: - UserError

struct UserError: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let actionTitle: String
    let action: UserErrorAction
    
    init(
        title: String,
        message: String,
        actionTitle: String = "OK",
        action: UserErrorAction = .dismiss
    ) {
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
}

// MARK: - UserErrorAction

enum UserErrorAction {
    case dismiss
    case retry
    case openSettings
    case openSupport
    case restart
}

// MARK: - Convenience Extensions

extension ErrorHandlingService {
    
    /// Log error with simplified syntax
    func log(_ error: Error, context: String? = nil) async {
        await logError(error, context: context)
    }
    
    /// Handle and show error in one call
    func handleAndShow(_ error: Error, context: String? = nil) async {
        let action = await handleError(error, context: context)
        
        switch action {
        case .showUserError(let userError):
            await showUserError(userError)
        case .silent:
            break
        default:
            // Handle other actions as needed
            break
        }
    }
}