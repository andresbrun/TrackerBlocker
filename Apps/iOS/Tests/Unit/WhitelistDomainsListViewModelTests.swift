import XCTest
import Combine
@testable import iOS

class WhitelistDomainsListViewModelTests: XCTestCase {
    var sut: WhitelistDomainsListViewModel!
    var managerMock: WhitelistDomainsManagerMock!
    var navigatorSpy: RootNavigatorSpy!
    var analyticsServicesSpy: AnalyticsServicesSpy!
    var cancellables: Set<AnyCancellable>!

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
