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
        // Arrange
        createSUT()
        
        // Act
        let domain = "example.com"
        let result = sut.addDomain(domain)
        
        // Assert
        XCTAssertTrue(result)
        XCTAssertTrue(managerMock.updates.value.contains(domain))
    }

    func testAddInvalidDomain() {
        // Arrange
        createSUT()
        
        // Act
        let domain = "invalid domain"
        let result = sut.addDomain(domain)
        
        // Assert
        XCTAssertFalse(result)
        XCTAssertEqual(
            navigatorSpy.presentAlertReceivedInvocations.last?.title,
            IOSStrings.Whitelistdomainsview.Alert.InvalidDomain.title
        )
    }

    func testAddDuplicateDomain() {
        // Arrange
        let domain = "example.com"
        managerMock.add(domain)
        createSUT()
        
        // Act
        let result = sut.addDomain(domain)
        
        // Assert
        XCTAssertFalse(result)
        XCTAssertEqual(
            navigatorSpy.presentAlertReceivedInvocations.last?.title,
            IOSStrings.Whitelistdomainsview.Alert.DuplicatedDomain.title
        )
    }

    func testRemoveDomainFromWhitelist() {
        // Arrange
        let domain = "example.com"
        managerMock.add(domain)
        createSUT()
        
        // Act
        sut.removeDomain(at: IndexSet(integer: 0))
        
        // Assert
        XCTAssertFalse(managerMock.domains.contains(domain))
    }

    func testToggleCurrentDomainEnableProtection() {
        // Arrange
        let domain = currentDomain
        createSUT()
        
        // Act
        sut.toggleCurrentDomain(enableProtection: true)
        
        // Assert
        XCTAssertFalse(managerMock.domains.contains(domain))
    }

    func testToggleCurrentDomainDisableProtection() {
        // Arrange
        let domain = currentDomain
        managerMock.add(domain)
        createSUT()
        
        // Act
        sut.toggleCurrentDomain(enableProtection: false)
        
        // Assert
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
