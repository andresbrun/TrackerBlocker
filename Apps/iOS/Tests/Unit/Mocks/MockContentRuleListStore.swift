import WebKit

@testable import iOS

class MockContentRuleListStore: ContentRuleListStoreProtocol {
    var mockCompilationSuccess: Bool = false
    var mockLookUpSuccess: Bool = false
    
    func lookUpContentRuleList(forIdentifier identifier: Identifier) async throws -> WKContentRuleList? {
        if mockLookUpSuccess {
            return await WKContentRuleList()
        } else {
            return nil
        }
    }
    
    func compileContentRuleList(forIdentifier identifier: Identifier, encodedContentRuleList: String) async throws -> WKContentRuleList? {
        if mockCompilationSuccess {
            return await WKContentRuleList()
        } else {
            return nil
        }
    }
    
    func removeContentRuleList(forIdentifier identifier: Identifier) async throws {}
} 
