import XCTest
import Combine
@testable import iOS

class WhitelistDomainsListViewModelTests: XCTestCase {
    var viewModel: WhitelistDomainsListViewModel!
    var mockManager: MockWhitelistDomainsManager!
    var mockNavigator: MockRootNavigator!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockManager = MockWhitelistDomainsManager()
        mockNavigator = MockRootNavigator()
        viewModel = WhitelistDomainsListViewModel(
            manager: mockManager,
            rootNavigator: mockNavigator
        )
        cancellables = []
    }

    override func tearDown() {
        viewModel = nil
        mockManager = nil
        mockNavigator = nil
        cancellables = nil
        super.tearDown()
    }

    func testAddDomainSuccessfully() async {
        let domain = "example.com"
        let result = viewModel.addDomain(domain)
        
        XCTAssertTrue(result)
        XCTAssertTrue(mockManager.updates.value.contains(domain))
    }

    func testAddInvalidDomain() {
        let domain = "invalid domain"
        let result = viewModel.addDomain(domain)
        
        XCTAssertFalse(result)
        XCTAssertEqual(mockNavigator.alertTitle, IOSStrings.Whitelistdomainsview.Alert.InvalidDomain.title)
    }

    func testAddDuplicateDomain() async {
        let domain = "example.com"
        viewModel.domains = [domain]
        
        let result = viewModel.addDomain(domain)
        
        XCTAssertFalse(result)
        XCTAssertEqual(mockNavigator.alertTitle, IOSStrings.Whitelistdomainsview.Alert.DuplicatedDomain.title)
    }
} 
