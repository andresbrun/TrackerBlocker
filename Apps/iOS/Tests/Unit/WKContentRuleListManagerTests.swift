import XCTest
import Combine
import WebKit

@testable import iOS

class WKContentRuleListManagerTests: XCTestCase {
    private let domain1 = "examples.domain1"
    private let domain2 = "examples.domain2"
    private let domain3 = "examples.domain2"
    
    private var userDefaults: MockUserDefaults!
    private var ruleListStore: MockContentRuleListStore!
    private var tdsAPI: MockTrackerDataSetAPI!
    private var fileCache: MockTDSFileStorageCache!
    private var whitelistDomainsUpdates: CurrentValueSubject<[String], Never>!
    private var ruleListStateUpdates: CurrentValueSubject<RuleListStateUpdates?, Never>!
    private var manager: WKContentRuleListManager!
    
    override func setUp() {
        super.setUp()
        resetMocks()
    }
    
    func testInitWithNoRulesCachedAndTDSNewETagTriggersInitialLoadAndNewTDS() {
        // ARRANGE
        arrangeForNoRulesCachedAndTDSNewETag()
        
        // ACT
        manager.onInit()
        
        // ASSERT
        assertRuleListUpdates(expected: [.initialLoad, .newTDS])
    }
    
    func testInitWithCachedRulesAndNoNewEtagTriggersInitialLoad() {
        // ARRANGE
        arrangeForCachedRulesAndNoNewEtag()
        
        // ACT
        manager.onInit()
        
        // ASSERT
        assertRuleListUpdates(expected: [.initialLoad])
    }
    
    func testInitWithOrphanIdentifierAndNoNewETagTriggersInitialLoad() {
        // ARRANGE
        arrangeForOrphanIdentifierAndNoNewETag()
        
        // ACT
        manager.onInit()
        
        // ASSERT
        assertRuleListUpdates(expected: [.initialLoad])
    }
    
    func testWhiteListDomainsUpdatesTriggersOneUpdate() {
        // ARRANGE
        arrangeForWhiteListDomainsUpdates(initialDomain: domain1)
        
        // ACT
        whitelistDomainsUpdates.send([domain1, domain2])
        
        // ASSERT
        assertRuleListUpdates(expected: [.whitelistUpdated(added: [domain2], removed: [])])
    }
    
    func testMultipleWhiteListUpdatesOnlyTriggersOneUpdate() {
        // ARRANGE
        arrangeForWhiteListDomainsUpdates(initialDomain: domain1)
        
        // ACT
        whitelistDomainsUpdates.send([domain1, domain2])
        whitelistDomainsUpdates.send([domain1])
        whitelistDomainsUpdates.send([domain1, domain3])
        
        // ASSERT
        assertRuleListUpdates(expected: [.whitelistUpdated(added: [domain3], removed: [])])
    }
    
    func testAddRemoveSameWhiteListUpdatesNotTriggerAnyUpdate() {
        // ARRANGE
        arrangeForWhiteListDomainsUpdates(initialDomain: domain1)
        
        // ACT
        whitelistDomainsUpdates.send([domain1, domain2])
        whitelistDomainsUpdates.send([domain1])
        
        // ASSERT
        assertNoRuleListUpdates()
    }
}

extension WKContentRuleListManagerTests {
    private func resetMocks() {
        userDefaults = MockUserDefaults()
        ruleListStore = MockContentRuleListStore()
        tdsAPI = MockTrackerDataSetAPI()
        fileCache = MockTDSFileStorageCache()
        whitelistDomainsUpdates = CurrentValueSubject<[String], Never>([])
        ruleListStateUpdates = CurrentValueSubject<RuleListStateUpdates?, Never>(nil)
        manager = createSut()
    }
    
    // MARK: - ARRANGE
    private func arrangeForNoRulesCachedAndTDSNewETag() {
        ruleListStore.mockCompilationSuccess = true
        tdsAPI.shouldFailDownload = false
    }

    private func arrangeForCachedRulesAndNoNewEtag() {
        userDefaults.setValue(
            "existing_etag",
            forKey: WKContentRuleListManager.Constants.EtagKey
        )
        userDefaults.setValue(
            "existing_etag_",
            forKey: WKContentRuleListManager.Constants.IdentifierKey
        )
        tdsAPI.shouldReturnNewEtag = false
        tdsAPI.shouldFailDownload = false
        ruleListStore.mockCompilationSuccess = true
        ruleListStore.mockLookUpSuccess = true
    }

    private func arrangeForOrphanIdentifierAndNoNewETag() {
        userDefaults.setValue(
            "prev_existing_etag",
            forKey: WKContentRuleListManager.Constants.EtagKey
        )
        userDefaults.setValue(
            "existing_etag_",
            forKey: WKContentRuleListManager.Constants.IdentifierKey
        )
        tdsAPI.shouldReturnNewEtag = false
        tdsAPI.shouldFailDownload = false
        ruleListStore.mockCompilationSuccess = true
        ruleListStore.mockLookUpSuccess = false
    }

    private func arrangeForWhiteListDomainsUpdates(initialDomain: String) {
        ruleListStore.mockCompilationSuccess = true
        tdsAPI.shouldFailDownload = false
        whitelistDomainsUpdates.send([initialDomain])
        manager.onInit()
        assertRuleListUpdates(expected: [.initialLoad, .newTDS])
    }

    // MARK: - ASSERT
    private func assertNoRuleListUpdates() {
        let expectation = XCTestExpectation(description: "Wait for no ruleListStateUpdates")
        expectation.isInverted = true
        
        let cancellable = ruleListStateUpdates.dropFirst().sink { update in
            guard update != nil else { return }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
        
        cancellable.cancel()
    }
    
    private func assertRuleListUpdates(
        expected: [CompilationReason],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let expectation = XCTestExpectation(description: "Wait for ruleListStateUpdates")
        expectation.expectedFulfillmentCount = expected.count
        
        var receivedReasons: [CompilationReason] = []
        // As it is a CurrentValueSubject we are not
        // interested on the previous value
        let cancellable = ruleListStateUpdates.dropFirst().sink { update in
            if let update = update {
                receivedReasons.append(update.reason)
            }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
        XCTAssertEqual(receivedReasons, expected, file: file, line: line)
        
        cancellable.cancel()
    }
    
    // MARK: - HELPERS
    private func createSut() -> WKContentRuleListManager {
        WKContentRuleListManager(
            userDefaults: userDefaults,
            ruleListStore: ruleListStore,
            tdsAPI: tdsAPI,
            fileCache: fileCache,
            whitelistDomainsUpdates: whitelistDomainsUpdates,
            ruleListStateUpdates: ruleListStateUpdates
        )
    }
}

extension CompilationReason: @retroactive Equatable {
    public static func == (lhs: CompilationReason, rhs: CompilationReason) -> Bool {
        switch (lhs, rhs) {
        case (.initialLoad, .initialLoad): 
            true
        case (.newTDS, .newTDS): 
            true
        case (.whitelistUpdated(let lhsAdded, let lhsRemoved), .whitelistUpdated(let rhsAdded, let rhsRemoved)): 
            lhsAdded == rhsAdded && lhsRemoved == rhsRemoved
        default: 
            false
        }
    }
}
