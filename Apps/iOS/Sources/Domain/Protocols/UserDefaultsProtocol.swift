import Foundation

protocol UserDefaultsProtocol {
    func string(forKey defaultName: String) -> String?
    func setValue(_ value: Any?, forKey key: String)
}

extension UserDefaults: UserDefaultsProtocol {} 