import WebKit

protocol ContentRuleListStoreProtocol {
    func lookUpContentRuleList(forIdentifier identifier: String) async throws -> WKContentRuleList?
    func compileContentRuleList(forIdentifier identifier: String, encodedContentRuleList: String) async throws -> WKContentRuleList?
    func removeContentRuleList(forIdentifier identifier: String) async throws
}

extension WKContentRuleListStore: ContentRuleListStoreProtocol {
    func lookUpContentRuleList(forIdentifier identifier: String) async throws -> WKContentRuleList? {
        return try await withCheckedThrowingContinuation { continuation in
            self.lookUpContentRuleList(
                forIdentifier: identifier
            ) { ruleList, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ruleList)
                }
            }
        }
    }
    
    func compileContentRuleList(
        forIdentifier identifier: String,
        encodedContentRuleList: String
    ) async throws -> WKContentRuleList? {
        return try await withCheckedThrowingContinuation { continuation in
            self.compileContentRuleList(
                forIdentifier: identifier,
                encodedContentRuleList: encodedContentRuleList
            ) { ruleList, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ruleList)
                }
            }
        }
    }
    
    func removeContentRuleList(forIdentifier identifier: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.removeContentRuleList(
                forIdentifier: identifier
            ) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
} 