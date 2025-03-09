import XCTest
import Combine
@testable import iOS

final class WhitelistDomainsListViewModelTests: XCTestCase {
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
        sut = WhitelistDomainsListViewModel(
            manager: managerMock,
            rootNavigator: navigatorSpy,
            currentDomain: "previous.com",
            analyticsServices: analyticsServicesSpy
        )
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
        let domain = "example.com"
        let result = sut.addDomain(domain)
        
        XCTAssertTrue(result)
        XCTAssertTrue(managerMock.updates.value.contains(domain))
    }

    func testAddInvalidDomain() {
        let domain = "invalid domain"
        let result = sut.addDomain(domain)
        
        XCTAssertFalse(result)
        XCTAssertEqual(
            navigatorSpy.presentAlertReceivedInvocations.last?.title,
            IOSStrings.Whitelistdomainsview.Alert.InvalidDomain.title
        )
    }

    func testAddDuplicateDomain() {
        let domain = "example.com"
        sut.domains = [domain]
        
        let result = sut.addDomain(domain)
        
        XCTAssertFalse(result)
        XCTAssertEqual(
            navigatorSpy.presentAlertReceivedInvocations.last?.title,
            IOSStrings.Whitelistdomainsview.Alert.DuplicatedDomain.title
        )
    }
} 
