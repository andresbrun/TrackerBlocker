import UIKit

@testable import iOS

class MockRootNavigator: NSObject, RootNavigator {
    var alertTitle: String?
    var alertDescription: String?
    
    func showWhiteListDomainsListView(currentDomain: String?) {}
    func initializeNavigation(in window: UIWindow) {}
    
    func presentAlert(title: String, description: String) {
        alertTitle = title
        alertDescription = description
    }
    
    func dismissLastPresentedViewController() {}
} 
