import Combine

@testable import iOS

class MockWhitelistDomainsManager: WhitelistDomainsManager {
    var updates = CurrentValueSubject<[String], Never>([])
    
    func getAll() async -> [String] {
        updates.value
    }
    
    func add(_ domain: String) async {
        updates.value.append(domain)
    }
    
    func remove(_ domain: String) async {
        updates.value.removeAll { $0 == domain }
    }
} 
