import Foundation
import Combine

protocol WhitelistDomainsManager {
    func getAll() -> [String]
    func add(_ domain: String)
    func remove(_ domain: String)
    
    var updates: CurrentValueSubject<[String], Never> { get }
}

extension WhitelistDomainsManager {
    func contains(_ url: URL?) -> Bool {
        guard let host = url?.host() else { return false }
        return getAll().contains(host)
    }
    
    func contains(_ host: String?) -> Bool {
        guard let host else { return false }
        return getAll().contains(host)
    }
}

final class DefaultWhitelistDomainsManager: WhitelistDomainsManager {
    private let fileManager = FileManager.default
    private let fileName = "whitelistDomains.txt"
    private var domains: Set<String> = [] {
        didSet {
            updates.send(Array(domains).sorted())
            saveDomains()
        }
    }

    // MARK: - Public
    let updates: CurrentValueSubject<[String], Never>
    
    init(whitelistDomainsUpdates: CurrentValueSubject<[String], Never>) {
        self.updates = whitelistDomainsUpdates
        loadDomains()
    }

    func getAll() -> [String] {
        Array(domains)
    }

    func add(_ domain: String) {
        guard !domain.isEmpty else { return }
        domains.insert(domain)
    }

    func remove(_ domain: String) {
        domains.remove(domain)
    }
    
    // MARK: - Private
    private func getFilePath() -> URL? {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsDirectory.appendingPathComponent(fileName)
    }

    private func loadDomains() {
        guard let filePath = getFilePath() else { return }
        if let data = try? Data(contentsOf: filePath),
           let savedDomains = String(data: data, encoding: .utf8) {
            domains = Set(savedDomains.components(separatedBy: "\n").filter { !$0.isEmpty })
        }
    }

    private func saveDomains() {
        guard let filePath = getFilePath() else { return }
        let domainsString = domains.joined(separator: "\n")
        try? domainsString.write(to: filePath, atomically: true, encoding: .utf8)
    }
}
