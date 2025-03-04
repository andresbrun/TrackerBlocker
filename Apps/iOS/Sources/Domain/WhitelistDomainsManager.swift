import Foundation
import Combine

protocol WhitelistDomainsManager {
    func getAll() async -> [String]
    func add(_ domain: String) async
    func remove(_ domain: String) async
    
    var updates: CurrentValueSubject<[String], Never> { get }
}

actor DefaultWhitelistDomainsManager: WhitelistDomainsManager {
    private let fileManager = FileManager.default
    private let fileName = "whitelistDomains.txt"
    private var domains: Set<String> = [] {
        didSet {
            updates.send(Array(domains).sorted())
        }
    }

    let updates: CurrentValueSubject<[String], Never>
    
    init(whitelistDomainsUpdates: CurrentValueSubject<[String], Never>) {
        self.updates = whitelistDomainsUpdates
        Task {
            await loadDomains()
        }
    }

    private func getFilePath() -> URL? {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsDirectory.appendingPathComponent(fileName)
    }

    private func loadDomains() async {
        guard let filePath = getFilePath() else { return }
        if let data = try? Data(contentsOf: filePath),
           let savedDomains = String(data: data, encoding: .utf8) {
            domains = Set(savedDomains.components(separatedBy: "\n").filter { !$0.isEmpty })
        }
    }

    private func saveDomains() async {
        guard let filePath = getFilePath() else { return }
        let domainsString = domains.joined(separator: "\n")
        try? domainsString.write(to: filePath, atomically: true, encoding: .utf8)
    }

    func getAll() async -> [String] {
        return Array(domains)
    }

    func add(_ domain: String) async {
        guard !domain.isEmpty else { return }
        domains.insert(domain)
        await saveDomains()
    }

    func remove(_ domain: String) async {
        domains.remove(domain)
        await saveDomains()
    }
}
