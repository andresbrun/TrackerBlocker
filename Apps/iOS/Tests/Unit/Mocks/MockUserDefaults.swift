import Foundation

@testable import iOS

class MockUserDefaults: UserDefaultsProtocol {
    private var storage = [String: Any]()
    
    func string(forKey defaultName: String) -> String? {
        storage[defaultName] as? String
    }
    
    func setValue(_ value: Any?, forKey key: String) {
        storage[key] = value
    }
    
    func data(forKey defaultName: String) -> Data? {
        storage[defaultName] as? Data
    }
}
