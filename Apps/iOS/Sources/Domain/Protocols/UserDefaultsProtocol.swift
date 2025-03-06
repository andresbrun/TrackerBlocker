import Foundation

protocol UserDefaultsProtocol {
    func string(forKey defaultName: String) -> String?
    func setValue(_ value: Any?, forKey key: String)
    func data(forKey defaultName: String) -> Data?
}

extension UserDefaults: UserDefaultsProtocol {} 