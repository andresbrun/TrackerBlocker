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
        // Arrange
        let expectation = XCTestExpectation(description: "Callback should be called with load URL")
        sut.callbacksPublisher.sink { callback in
            if case .load(let url) = callback {
                XCTAssertEqual(url.absoluteString, Constants.URL.DefaultSearchEngine)
                expectation.fulfill()
            }
        }.store(in: &cancellables)
        
        // Act
        sut.loadDefaultPage()
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
    }

    func testTryToLoadValidURL() {
        // Arrange
        let validURLString = "https://example.com"
        let expectation = XCTestExpectation(description: "Callback should be called with load URL")
        sut.callbacksPublisher.sink { callback in
            if case .load(let url) = callback {
                XCTAssertEqual(url.absoluteString, validURLString)
                expectation.fulfill()
            }
        }.store(in: &cancellables)
        
        // Act
        let result = sut.tryToLoad(absoluteString: validURLString)
        
        // Assert
        XCTAssertTrue(result)
        wait(for: [expectation], timeout: 1.0)
    }

    func testTryToLoadInvalidURLShouldSearchInstead() {
        // Arrange
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
        
        // Act
        let result = sut.tryToLoad(absoluteString: invalidURLString)
        
        // Assert
        XCTAssertTrue(result)
        wait(for: [expectation], timeout: 1.0)
    }

    func testReloadCurrentPage() {
        // Arrange
        let currentURL = URL(string: "https://example.com")!
        sut.currentURL = currentURL
        let expectation = XCTestExpectation(description: "Callback should be called with reload URL")
        sut.callbacksPublisher.sink { callback in
            if case .load(let url) = callback {
                XCTAssertEqual(url, currentURL)
                expectation.fulfill()
            }
        }.store(in: &cancellables)
        
        // Act
        sut.reloadCurrentPage()
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
    }

    func testGoBack() {
        // Arrange
        let expectation = XCTestExpectation(description: "Callback should be called with goBack")
        sut.callbacksPublisher.sink { callback in
            if case .goBack = callback {
                expectation.fulfill()
            }
        }.store(in: &cancellables)
        
        // Act
        sut.goBack()
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
    }

    func testGoForward() {
        // Arrange
        let expectation = XCTestExpectation(description: "Callback should be called with goForward")
        sut.callbacksPublisher.sink { callback in
            if case .goForward = callback {
                expectation.fulfill()
            }
        }.store(in: &cancellables)
        
        // Act
        sut.goForward()
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
    }

    func testShowWhiteListDomainsListView() {
        // Act
        sut.showWhiteListDomainsListView()
        
        // Assert
        XCTAssertFalse(navigatorSpy.showWhiteListDomainsListViewReceivedInvocations.isEmpty)
    }

    func testRuleListStateUpdatesReloadsCurrentWebsite() {
        // Arrange
        let currentURL = URL(string: "https://example.com")!
        sut.currentURL = currentURL
        let expectation = XCTestExpectation(description: "Callback should be called with reload URL")
        
        sut.callbacksPublisher.sink { callback in
            if case .load(let url) = callback {
                XCTAssertEqual(url, currentURL)
                expectation.fulfill()
            }
        }.store(in: &cancellables)
        
        // Act
        ruleListStateUpdatesMock.send(
            RuleListStateUpdates(
                ruleList: WKContentRuleList(),
                reason: .whitelistUpdated(added: ["example.com"], removed: [])
            )
        )
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
    }

    func testRuleListStateUpdatesDoesNotReloadForUnrelatedUpdates() {
        // Arrange
        let currentURL = URL(string: "https://example.com")!
        sut.currentURL = currentURL
        let expectation = XCTestExpectation(description: "Callback should not be called")
        expectation.isInverted = true
        
        sut.callbacksPublisher.sink { callback in
            if case .load = callback {
                expectation.fulfill()
            }
        }.store(in: &cancellables)
        
        // Act
        ruleListStateUpdatesMock.send(
            RuleListStateUpdates(
                ruleList: WKContentRuleList(),
                reason: .whitelistUpdated(added: ["unrelated.com"], removed: [])
            )
        )
        
        // Assert
        wait(for: [expectation], timeout: 1.0)
    }
} 
