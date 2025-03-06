import WebKit

protocol ContentRuleListStoreProtocol {
    func lookUpContentRuleList(forIdentifier identifier: Identifier) async throws -> WKContentRuleList?
    func compileContentRuleList(forIdentifier identifier: Identifier, encodedContentRuleList: String) async throws -> WKContentRuleList?
    func removeContentRuleList(forIdentifier identifier: Identifier) async throws
}

extension WKContentRuleListStore: ContentRuleListStoreProtocol {
    func lookUpContentRuleList(forIdentifier identifier: Identifier) async throws -> WKContentRuleList? {
        return try await withCheckedThrowingContinuation { continuation in
            self.lookUpContentRuleList(
                forIdentifier: identifier.value
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
        forIdentifier identifier: Identifier,
        encodedContentRuleList: String
    ) async throws -> WKContentRuleList? {
        return try await withCheckedThrowingContinuation { continuation in
            self.compileContentRuleList(
                forIdentifier: identifier.value,
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
    
    func removeContentRuleList(forIdentifier identifier: Identifier) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.removeContentRuleList(
                forIdentifier: identifier.value
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
