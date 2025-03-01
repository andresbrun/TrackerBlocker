import os
import Foundation

public extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!
    private static var defaultCategory = "default"
    static let `default` = Logger(subsystem: subsystem, category: defaultCategory)
}
