import XCTest
import Combine
import WebKit

@testable import iOS

class WKContentRuleListManagerTests: XCTestCase {
    private let domain1 = "examples.domain1"
    private let domain2 = "examples.domain2"
    private let domain3 = "examples.domain2"
    
    private var userDefaultsMock: UserDefaultsMock!
    private var ruleListStoreMock: ContentRuleListStoreMock!
    private var tdsAPIMock: TrackerDataSetAPIMock!
    private var fileCacheMock: TDSFileStorageCacheMock!
    private var whitelistDomainsUpdates: CurrentValueSubject<[String], Never>!
    private var ruleListStateUpdates: CurrentValueSubject<RuleListStateUpdates?, Never>!
    private var analyticsServicesSpy: AnalyticsServicesSpy!
    
    private var sut: WKContentRuleListManager!
    
    override func setUp() {
        super.setUp()
        resetMocks()
    }
    
    func testInitWithNoRulesCachedAndTDSNewETagTriggersInitialLoadAndNewTDS() {
        // ARRANGE
        arrangeForNoRulesCachedAndTDSNewETag()
        
        // ACT
        sut.onInit()
        
        // ASSERT
        assertRuleListUpdates(expected: [.initialLoad, .newTDS])
    }
    
    func testInitWithCachedRulesAndNoNewEtagTriggersInitialLoad() {
        // ARRANGE
        arrangeForCachedRulesAndNoNewEtag()
        
        // ACT
        sut.onInit()
        
        // ASSERT
        assertRuleListUpdates(expected: [.initialLoad])
    }
    
    func testInitWithOrphanIdentifierAndNoNewETagTriggersInitialLoad() {
        // ARRANGE
        arrangeForOrphanIdentifierAndNoNewETag()
        
        // ACT
        sut.onInit()
        
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
        userDefaultsMock = UserDefaultsMock()
        ruleListStoreMock = ContentRuleListStoreMock()
        tdsAPIMock = TrackerDataSetAPIMock()
        fileCacheMock = TDSFileStorageCacheMock()
        whitelistDomainsUpdates = CurrentValueSubject<[String], Never>([])
        ruleListStateUpdates = CurrentValueSubject<RuleListStateUpdates?, Never>(nil)
        analyticsServicesSpy = AnalyticsServicesSpy()
        sut = createSut()
    }
    
    // MARK: - ARRANGE
    private func arrangeForNoRulesCachedAndTDSNewETag() {
        ruleListStoreMock.mockCompilationSuccess = true
        tdsAPIMock.shouldFailDownload = false
    }

    private func arrangeForCachedRulesAndNoNewEtag() {
        userDefaultsMock.setValue(
            "existing_etag",
            forKey: Constants.Key.Etag
        )
        userDefaultsMock.setValue(
            try! JSONEncoder().encode(WKContentRuleListIdentifier(etag: "existing_etag", domains: [])),
            forKey: Constants.Key.Identifier
        )
        tdsAPIMock.shouldReturnNewEtag = false
        tdsAPIMock.shouldFailDownload = false
        ruleListStoreMock.mockCompilationSuccess = true
        ruleListStoreMock.mockLookUpSuccess = true
    }

    private func arrangeForOrphanIdentifierAndNoNewETag() {
        userDefaultsMock.setValue(
            "prev_etag",
            forKey: Constants.Key.Etag
        )
        userDefaultsMock.setValue(
            try! JSONEncoder().encode(WKContentRuleListIdentifier(etag: "new_etag", domains: [])),
            forKey: Constants.Key.Identifier
        )
        tdsAPIMock.shouldReturnNewEtag = false
        tdsAPIMock.shouldFailDownload = false
        ruleListStoreMock.mockCompilationSuccess = true
        ruleListStoreMock.mockLookUpSuccess = false
    }

    private func arrangeForWhiteListDomainsUpdates(initialDomain: String) {
        ruleListStoreMock.mockCompilationSuccess = true
        ruleListStoreMock.mockCompilationTimeDelay = true
        tdsAPIMock.shouldFailDownload = false
        whitelistDomainsUpdates.send([initialDomain])
        sut.onInit()
        assertRuleListUpdates(expected: [.initialLoad, .newTDS])
    }

    // MARK: - ASSERT
    private func assertNoRuleListUpdates() {
        let expectation = XCTestExpectation(description: "Wait for no ruleListStateUpdates")
        expectation.isInverted = true
        
        // As it is a CurrentValueSubject we are not
        // interested on the previous value
        let cancellable = ruleListStateUpdates.dropFirst().sink { update in
            guard update != nil else { return }
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3.0)
        
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
            userDefaults: userDefaultsMock,
            ruleListStore: ruleListStoreMock,
            tdsAPI: tdsAPIMock,
            fileCache: fileCacheMock,
            whitelistDomainsUpdates: whitelistDomainsUpdates,
            ruleListStateUpdates: ruleListStateUpdates,
            analyticsServices: analyticsServicesSpy
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
