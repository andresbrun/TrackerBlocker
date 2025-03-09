import Foundation

struct AppEnvironment {
    static var isRunningTests: Bool {
        NSClassFromString("XCTestCase") != nil
    }
}
