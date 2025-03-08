import Foundation

struct WKContentRuleListIdentifier: Codable {
    let etag: String?
    let domains: [String]
    
    var value: String {
        let sortedDomainsHash = domains.sorted().joined().data(using: .utf8)?.base64EncodedString() ?? ""
        return "\(etag ?? "local_file")_\(sortedDomainsHash)"
    }
}
