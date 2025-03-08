import UIKit

@testable import iOS

final class RootNavigatorSpy: NSObject, RootNavigator {
    
    func showWhiteListDomainsListView(currentDomain: String?) {}
    func initializeNavigation(in window: UIWindow) {}
    
    var presentAlertReceivedInvocations: [(title: String, description: String)] = []
    func presentAlert(title: String, description: String) {
        presentAlertReceivedInvocations.append((title: title, description: description))
    }
    
    func dismissLastPresentedViewController() {}
} 
