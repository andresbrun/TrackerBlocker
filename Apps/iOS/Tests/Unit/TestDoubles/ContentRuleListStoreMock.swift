import WebKit

@testable import iOS

final class ContentRuleListStoreMock: ContentRuleListStoreProtocol {
    var mockCompilationSuccess: Bool = false
    var mockLookUpSuccess: Bool = false
    var mockCompilationTimeDelay: Bool = false
    
    func lookUpContentRuleList(
        forIdentifier identifier: WKContentRuleListIdentifier
    ) async throws -> WKContentRuleList? {
        if mockLookUpSuccess {
            return await WKContentRuleList()
        } else {
            return nil
        }
    }
    
    func compileContentRuleList(
        forIdentifier identifier: WKContentRuleListIdentifier,
        encodedContentRuleList: String
    ) async throws -> WKContentRuleList? {
        if mockCompilationSuccess {
            if mockCompilationTimeDelay {
                try await Task.sleep(for: .milliseconds(100))
            }
            return await WKContentRuleList()
        } else {
            return nil
        }
    }
    
    func removeContentRuleList(
        forIdentifier identifier: WKContentRuleListIdentifier
    ) async throws {}
}
