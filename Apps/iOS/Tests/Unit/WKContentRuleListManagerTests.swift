import XCTest
import Combine
import WebKit

@testable import iOS

// Mock classes
class MockUserDefaults: UserDefaultsProtocol {
    private var storage = [String: Any]()
    
    func string(forKey defaultName: String) -> String? {
        return storage[defaultName] as? String
    }
    
    func setValue(_ value: Any?, forKey key: String) {
        storage[key] = value
    }
}

class MockContentRuleListStore: ContentRuleListStoreProtocol {
    var mockCompilationSuccess: Bool = false
    var mockLookUpSuccess: Bool = false
    
    func lookUpContentRuleList(forIdentifier identifier: String) async throws -> WKContentRuleList? {
        if mockLookUpSuccess {
            return await WKContentRuleList()
        } else {
            return nil
        }
    }
    
    func compileContentRuleList(forIdentifier identifier: String, encodedContentRuleList: String) async throws -> WKContentRuleList? {
        if mockCompilationSuccess {
            return await WKContentRuleList()
        } else {
            return nil
        }
    }
    
    func removeContentRuleList(forIdentifier identifier: String) async throws {}
}

extension Data {
    static var mockedData: [String: Any] = [
        "trackers": [
            "1558334541.rsc.cdn77.org": [
                "domain": "1558334541.rsc.cdn77.org",
                "owner": [
                    "name": "DataCamp Limited",
                    "displayName": "DataCamp"
                ],
                "prevalence": 0.0000613,
                "fingerprinting": 3,
                "cookies": 0.0000545,
                "categories": [],
                "default": "ignore",
                "rules": [
                    [
                        "rule": "1558334541\\.rsc\\.cdn77\\.org\\/nfs\\/20221227\\/etp\\.min\\.js",
                        "fingerprinting": 3,
                        "cookies": 0.0000136
                    ],
                    [
                        "rule": "1558334541\\.rsc\\.cdn77\\.org\\/nfs\\/20221104\\/etpnoauid\\.min\\.js",
                        "fingerprinting": 3,
                        "cookies": 0.0000136
                    ]
                ]
            ]
        ],
        "entities": [
            "DataCamp Limited": [
                "domains": [
                    "cdn77.org",
                    "datacamp.com",
                    "rdocumentation.org"
                ],
                "prevalence": 0.0551,
                "displayName": "DataCamp"
            ]
        ],
        "domains": [
            "cdn77.org": "DataCamp Limited"
        ],
        "cnames": [
            "aax-eu.amazon.se": "aax-eu-retail-direct.amazon-adsystem.com"
        ]
    ]
    
    static var mockedTDS: Data {
        try! JSONSerialization.data(
            withJSONObject: mockedData,
            options: []
        )
    }
}

class MockTrackerDataSetAPI: TrackerDataSetAPI {
    var shouldFailDownload = false
    var shouldReturnNewEtag = true
    
    func downloadLatestTDS(
        withETag: String?
    ) async throws -> (data: Data?, etag: String?) {
        try await Task.sleep(for: .seconds(0.1))
        if shouldFailDownload {
            throw NSError(domain: "NetworkError", code: -1, userInfo: nil)
        }
        if shouldReturnNewEtag {
            return (.mockedTDS, "newETag")
        } else {
            return (nil, nil)
        }
    }
}

class MockTDSFileStorageCache: TDSFileStorageCache {
    var savedInvocation: (Data, String)?
    
    func save(_ data: Data, forETag etag: String) {
        savedInvocation = (data, etag)
    }
    
    func getData(forETag etag: String?) throws -> Data {
        .mockedTDS
    }
}

// Test class
class WKContentRuleListManagerTests: XCTestCase {
    var userDefaults: MockUserDefaults!
    var ruleListStore: MockContentRuleListStore!
    var tdsAPI: MockTrackerDataSetAPI!
    var fileCache: MockTDSFileStorageCache!
    var whitelistDomainsUpdates: CurrentValueSubject<[String], Never>!
    var ruleListStateUpdates: CurrentValueSubject<RuleListStateUpdates?, Never>!
    var manager: WKContentRuleListManager!
    
    override func setUp() {
        super.setUp()
        resetMocks()
    }
    
    func testInitWithNoRulesCachedAndTDSNewETag() {
        // ARRANGE
        ruleListStore.mockCompilationSuccess = true
        tdsAPI.shouldFailDownload = false
        
        // ACT
        manager.onInit()
        
        // ASSERT
        assertRuleListUpdates(expected: [.initialLoad, .newTDS])
    }
    
    func testInitWithCachedRulesAndNoNewEtag() {
        // ARRANGE
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
        
        // ACT
        manager.onInit()
        
        // ASSERT
        assertRuleListUpdates(expected: [.initialLoad])
    }
    
    // Should Compile last saved file
    func testInitWithOrphanIdentifierAndNoNewETag() {
        // ARRANGE
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
        
        // ACT
        manager.onInit()
        
        // ASSERT
        assertRuleListUpdates(expected: [.initialLoad])
    }
    
    func testWhiteListDomainsUpdates() {
        let domain1 = "examples.domain1"
        let domain2 = "examples.domain2"
        
        // ARRANGE
        ruleListStore.mockCompilationSuccess = true
        tdsAPI.shouldFailDownload = false
        whitelistDomainsUpdates.send([domain1])
        manager.onInit()
        assertRuleListUpdates(expected: [.initialLoad, .newTDS])
        
        // ACT
        whitelistDomainsUpdates.send([domain1, domain2])
        
        // ASSERT
        assertRuleListUpdates(expected: [.whitelistUpdated(added: [domain2], removed: [])])
    }
    
    func testMultipleWhiteListUpdatesOnlyTriggerOneUpdate() {
        let domain1 = "examples.domain1"
        let domain2 = "examples.domain2"
        let domain3 = "examples.domain2"
        
        // ARRANGE
        ruleListStore.mockCompilationSuccess = true
        tdsAPI.shouldFailDownload = false
        whitelistDomainsUpdates.send([domain1])
        manager.onInit()
        assertRuleListUpdates(expected: [.initialLoad, .newTDS])
        
        // ACT
        whitelistDomainsUpdates.send([domain1, domain2])
        whitelistDomainsUpdates.send([domain1])
        whitelistDomainsUpdates.send([domain1, domain3])
        
        // ASSERT
        assertRuleListUpdates(expected: [.whitelistUpdated(added: [domain3], removed: [])])
    }
    
    func testAddRemoveSameWhiteListUpdatesNotTriggerAnyUpdate() {
        let domain1 = "examples.domain1"
        let domain2 = "examples.domain2"
        
        // ARRANGE
        ruleListStore.mockCompilationSuccess = true
        tdsAPI.shouldFailDownload = false
        whitelistDomainsUpdates.send([domain1])
        manager.onInit()
        assertRuleListUpdates(expected: [.initialLoad, .newTDS])
        
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
        case (.initialLoad, .initialLoad): true
        case (.newTDS, .newTDS): true
        case (.whitelistUpdated(let lhsAdded, let lhsRemoved), .whitelistUpdated(let rhsAdded, let rhsRemoved)): lhsAdded == rhsAdded && lhsRemoved == rhsRemoved
        default: false
        }
    }
}
