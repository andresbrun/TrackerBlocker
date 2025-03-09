import XCTest
import WebKit
import Combine

@testable import iOS

final class WebViewModelTests: XCTestCase {
    private var whitelistDomainsManagerMock: WhitelistDomainsManagerMock!
    private var ruleListStateUpdatesMock: CurrentValueSubject<RuleListStateUpdates?, Never>!
    private var navigatorSpy: RootNavigatorSpy!
    private var featureProviderMock: FeatureProviderMock!
    private var analyticsServicesSpy: AnalyticsServicesSpy!
    private var cancellables: Set<AnyCancellable> = []
    
    private var sut: WebViewModel!

    override func setUp() {
        super.setUp()
        whitelistDomainsManagerMock = WhitelistDomainsManagerMock()
        ruleListStateUpdatesMock = CurrentValueSubject<RuleListStateUpdates?, Never>(nil)
        navigatorSpy = RootNavigatorSpy()
        featureProviderMock = FeatureProviderMock()
        analyticsServicesSpy = AnalyticsServicesSpy()
        
        sut = WebViewModel(
            whitelistDomainsManager: whitelistDomainsManagerMock,
            ruleListStateUpdates: ruleListStateUpdatesMock,
            navigator: navigatorSpy,
            featureStore: FeatureStore(
                provider: featureProviderMock
            ),
            analyticsServices: analyticsServicesSpy
        )
        
        cancellables.removeAll()
    }

    override func tearDown() {
        sut = nil
        whitelistDomainsManagerMock = nil
        ruleListStateUpdatesMock = nil
        navigatorSpy = nil
        featureProviderMock = nil
        analyticsServicesSpy = nil
        cancellables.removeAll()
        super.tearDown()
    }

    func testLoadDefaultPage() {
        // ARRANGE
        let expectation = XCTestExpectation(description: "Callback should be called with load URL")
        sut.callbacksPublisher.sink { callback in
            if case .load(let url) = callback {
                XCTAssertEqual(url.absoluteString, Constants.URL.DefaultSearchEngine)
                expectation.fulfill()
            }
        }.store(in: &cancellables)
        
        // ACT
        sut.loadDefaultPage()
        
        // ASSERT
        wait(for: [expectation], timeout: 1.0)
    }

    func testTryToLoadValidURL() {
        // ARRANGE
        let validURLString = "https://example.com"
        let expectation = XCTestExpectation(description: "Callback should be called with load URL")
        sut.callbacksPublisher.sink { callback in
            if case .load(let url) = callback {
                XCTAssertEqual(url.absoluteString, validURLString)
                expectation.fulfill()
            }
        }.store(in: &cancellables)
        
        // ACT
        let result = sut.tryToLoad(absoluteString: validURLString)
        
        // ASSERT
        XCTAssertTrue(result)
        wait(for: [expectation], timeout: 1.0)
    }

    func testTryToLoadInvalidURLShouldSearchInstead() {
        // ARRANGE
        let invalidURLString = "invalid url"
        let expectation = XCTestExpectation(description: "Callback should be called with search URL")
        sut.callbacksPublisher.sink { callback in
            if case .load(let url) = callback {
                XCTAssertEqual(
                    url.absoluteString,
                    Constants.URL.DefaultSearchEngine + "?q=invalid%20url"
                )
                expectation.fulfill()
            }
        }.store(in: &cancellables)
        
        // ACT
        let result = sut.tryToLoad(absoluteString: invalidURLString)
        
        // ASSERT
        XCTAssertTrue(result)
        wait(for: [expectation], timeout: 1.0)
    }

    func testReloadCurrentPage() {
        // ARRANGE
        let currentURL = URL(string: "https://example.com")!
        sut.currentURL = currentURL
        let expectation = XCTestExpectation(description: "Callback should be called with reload URL")
        sut.callbacksPublisher.sink { callback in
            if case .load(let url) = callback {
                XCTAssertEqual(url, currentURL)
                expectation.fulfill()
            }
        }.store(in: &cancellables)
        
        // ACT
        sut.reloadCurrentPage()
        
        // ASSERT
        wait(for: [expectation], timeout: 1.0)
    }

    func testGoBack() {
        // ARRANGE
        let expectation = XCTestExpectation(description: "Callback should be called with goBack")
        sut.callbacksPublisher.sink { callback in
            if case .goBack = callback {
                expectation.fulfill()
            }
        }.store(in: &cancellables)
        
        // ACT
        sut.goBack()
        
        // ASSERT
        wait(for: [expectation], timeout: 1.0)
    }

    func testGoForward() {
        // ARRANGE
        let expectation = XCTestExpectation(description: "Callback should be called with goForward")
        sut.callbacksPublisher.sink { callback in
            if case .goForward = callback {
                expectation.fulfill()
            }
        }.store(in: &cancellables)
        
        // ACT
        sut.goForward()
        
        // ASSERT
        wait(for: [expectation], timeout: 1.0)
    }

    func testShowWhiteListDomainsListView() {
        // ACT
        sut.showWhiteListDomainsListView()
        
        // ASSERT
        XCTAssertFalse(navigatorSpy.showWhiteListDomainsListViewReceivedInvocations.isEmpty)
    }

    func testRuleListStateUpdatesReloadsCurrentWebsite() {
        // ARRANGE
        let currentURL = URL(string: "https://example.com")!
        sut.currentURL = currentURL
        let expectation = XCTestExpectation(description: "Callback should be called with reload URL")
        
        sut.callbacksPublisher.sink { callback in
            if case .load(let url) = callback {
                XCTAssertEqual(url, currentURL)
                expectation.fulfill()
            }
        }.store(in: &cancellables)
        
        // ACT
        ruleListStateUpdatesMock.send(
            RuleListStateUpdates(
                ruleList: WKContentRuleList(),
                reason: .whitelistUpdated(added: ["example.com"], removed: [])
            )
        )
        
        // ASSERT
        wait(for: [expectation], timeout: 1.0)
    }

    func testRuleListStateUpdatesDoesNotReloadForUnrelatedUpdates() {
        // ARRANGE
        let currentURL = URL(string: "https://example.com")!
        sut.currentURL = currentURL
        let expectation = XCTestExpectation(description: "Callback should not be called")
        expectation.isInverted = true
        
        sut.callbacksPublisher.sink { callback in
            if case .load = callback {
                expectation.fulfill()
            }
        }.store(in: &cancellables)
        
        // ACT
        ruleListStateUpdatesMock.send(
            RuleListStateUpdates(
                ruleList: WKContentRuleList(),
                reason: .whitelistUpdated(added: ["unrelated.com"], removed: [])
            )
        )
        
        // ASSERT
        wait(for: [expectation], timeout: 1.0)
    }
} 
