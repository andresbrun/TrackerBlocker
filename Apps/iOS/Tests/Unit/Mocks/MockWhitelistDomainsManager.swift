import Combine

@testable import iOS

class MockWhitelistDomainsManager: WhitelistDomainsManager {
    var updates = CurrentValueSubject<[String], Never>([])
    
    func getAll() -> [String] {
        updates.value
    }
    
    func add(_ domain: String) {
        updates.value.append(domain)
    }
    
    func remove(_ domain: String) {
        updates.value.removeAll { $0 == domain }
    }
} 
