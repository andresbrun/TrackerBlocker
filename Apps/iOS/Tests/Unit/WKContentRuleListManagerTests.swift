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
    
    func downloadLatestTDS(withETag: String?) async throws -> (data: Data?, etag: String?) {
        if shouldFailDownload {
            throw NSError(domain: "NetworkError", code: -1, userInfo: nil)
        }
        await Thread.sleep(until: Date().addingTimeInterval(0.1))
        return (.mockedTDS, "newETag")
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
    
    private func resetMocks() {
        userDefaults = MockUserDefaults()
        ruleListStore = MockContentRuleListStore()
        tdsAPI = MockTrackerDataSetAPI()
        fileCache = MockTDSFileStorageCache()
        whitelistDomainsUpdates = CurrentValueSubject<[String], Never>([])
        ruleListStateUpdates = CurrentValueSubject<RuleListStateUpdates?, Never>(nil)
        manager = createSut()
    }
    
    ///userDefaults // ETag e Identifier
    ///ruleListStore // lookup  and compile
    ///tdsAPI // downloadLatestTDS
    ///fileCache // safeFile, getData
    ///Flows:
    ///  Init with no cache (userDefaults Identifier) tdsAPI succeess (new Etag) -> 2 compilations .initial + .newTDS
    ///
    ///  Init with no cache (userDefaults Identifier)  tdsAPI failure -> 1 compilation .initial
    ///  Init with cache tdsAPI succeess -> 2 compilations .initial + .newTDS
    ///  Init with cache tdsAPI failure -> 1 compilation .initial
    ///
    
    func testInitWithNoRulesCachedAndTDSNewETag() {
        // ARRANGE
        ruleListStore.mockCompilationSuccess = true
        tdsAPI.shouldFailDownload = false
        
        // ACT
        manager.onInit()
        
        // ASSERT
        let expectation = XCTestExpectation(description: "Wait for ruleListStateUpdates")
        
        var receivedReasons: [CompilationReason] = []
        let cancellable = ruleListStateUpdates.sink { update in
            if let update = update {
                receivedReasons.append(update.reason)
            }
            if receivedReasons.count == 2 {
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 3.0)
        XCTAssertEqual(receivedReasons, [.initialLoad, .newTDS])
        
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
