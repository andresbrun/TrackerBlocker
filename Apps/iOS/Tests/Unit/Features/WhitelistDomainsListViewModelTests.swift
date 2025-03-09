import XCTest
import Combine
@testable import iOS

final class WhitelistDomainsListViewModelTests: XCTestCase {
    private let currentDomain = "current.com"
    
    private var managerMock: WhitelistDomainsManagerMock!
    private var navigatorSpy: RootNavigatorSpy!
    private var analyticsServicesSpy: AnalyticsServicesSpy!
    private var cancellables: Set<AnyCancellable>!
    
    private var sut: WhitelistDomainsListViewModel!

    override func setUp() {
        super.setUp()
        analyticsServicesSpy = AnalyticsServicesSpy()
        managerMock = WhitelistDomainsManagerMock()
        navigatorSpy = RootNavigatorSpy()
        cancellables = []
    }

    override func tearDown() {
        sut = nil
        managerMock = nil
        navigatorSpy = nil
        cancellables = nil
        super.tearDown()
    }

    func testAddDomainSuccessfully() {
        // ARRANGE
        createSUT()
        
        // ACT
        let domain = "example.com"
        let result = sut.addDomain(domain)
        
        // ASSERT
        XCTAssertTrue(result)
        XCTAssertTrue(managerMock.updates.value.contains(domain))
    }

    func testAddInvalidDomain() {
        // ARRANGE
        createSUT()
        
        // ACT
        let domain = "invalid domain"
        let result = sut.addDomain(domain)
        
        // ASSERT
        XCTAssertFalse(result)
        XCTAssertEqual(
            navigatorSpy.presentAlertReceivedInvocations.last?.title,
            IOSStrings.Whitelistdomainsview.Alert.InvalidDomain.title
        )
    }

    func testAddDuplicateDomain() {
        // ARRANGE
        let domain = "example.com"
        managerMock.add(domain)
        createSUT()
        
        // ACT
        let result = sut.addDomain(domain)
        
        // ASSERT
        XCTAssertFalse(result)
        XCTAssertEqual(
            navigatorSpy.presentAlertReceivedInvocations.last?.title,
            IOSStrings.Whitelistdomainsview.Alert.DuplicatedDomain.title
        )
    }

    func testRemoveDomainFromWhitelist() {
        // ARRANGE
        let domain = "example.com"
        managerMock.add(domain)
        createSUT()
        
        // ACT
        sut.removeDomain(at: IndexSet(integer: 0))
        
        // ASSERT
        XCTAssertFalse(managerMock.domains.contains(domain))
    }

    func testToggleCurrentDomainEnableProtection() {
        // ARRANGE
        let domain = currentDomain
        createSUT()
        
        // ACT
        sut.toggleCurrentDomain(enableProtection: true)
        
        // ASSERT
        XCTAssertFalse(managerMock.domains.contains(domain))
    }

    func testToggleCurrentDomainDisableProtection() {
        // ARRANGE
        let domain = currentDomain
        managerMock.add(domain)
        createSUT()
        
        // ACT
        sut.toggleCurrentDomain(enableProtection: false)
        
        // ASSERT
        XCTAssertTrue(sut.domains.contains(domain))
    }
} 

extension WhitelistDomainsListViewModelTests {
    func createSUT() {
        sut = WhitelistDomainsListViewModel(
            manager: managerMock,
            rootNavigator: navigatorSpy,
            currentDomain: currentDomain,
            analyticsServices: analyticsServicesSpy
        )
    }
}
