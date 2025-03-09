import Combine

@testable import iOS

final class WhitelistDomainsManagerMock: WhitelistDomainsManager {
    var domains: Set<String> = [] {
        didSet {
            updates.send(Array(domains).sorted())
        }
    }
    var updates = CurrentValueSubject<[String], Never>([])
    
    func getAll() -> [String] {
        Array(domains).sorted()
    }
    
    func add(_ domain: String) {
        domains.insert(domain)
    }
    
    func remove(_ domain: String) {
        domains.remove(domain)
    }
} 
