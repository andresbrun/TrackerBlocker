import os
import Foundation

public extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!
    private static var defaultCategory = "default"
    static let `default` = Logger(subsystem: subsystem, category: defaultCategory)

    private func formattedTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: Date())
    }
    
    func log(_ message: String, level: OSLogType = .default) {
        let timestamp = formattedTimestamp()
        Logger.default.log(level: level, "\(timestamp) - \(message)")
    }
    
    func debug(_ message: String) {
        log(message, level: .debug)
    }
    
    func info(_ message: String) {
        log(message, level: .info)
    }
    
    func error(_ message: String) {
        log(message, level: .error)
    }
    
    func fault(_ message: String) {
        log(message, level: .fault)
    }
}
