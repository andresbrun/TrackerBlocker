import UIKit

@testable import iOS

final class RootNavigatorSpy: NSObject, RootNavigator {
    
    var showWhiteListDomainsListViewReceivedInvocations: [String?] = []
    func showWhiteListDomainsListView(currentDomain: String?) {
        showWhiteListDomainsListViewReceivedInvocations.append(currentDomain)
    }
    func initializeNavigation(in window: UIWindow) {}
    
    var presentAlertReceivedInvocations: [(title: String, description: String)] = []
    func presentAlert(title: String, description: String) {
        presentAlertReceivedInvocations.append((title: title, description: description))
    }
    
    func dismissLastPresentedViewController() {}
} 
