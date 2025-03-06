import Foundation
import UIKit

protocol RootNavigator: NSObject {
    func showWhiteListDomainsListView()
    func initializeNavigation(in window: UIWindow)

    func presentAlert(title: String, description: String)
    
    func dismissLastPresentedViewController()
}

class AppRootNavigator: NSObject, RootNavigator {
    private let appCompositionRoot: AppCompositionRoot
    private var rootNavigationController: UINavigationController?
    private var visibleViewController: UIViewController? {
        rootNavigationController?.visibleViewController
    }
    
    init(appCompositionRoot: AppCompositionRoot) {
        self.appCompositionRoot = appCompositionRoot
        super.init()
        appCompositionRoot.rootNavigator = self
    }
    
    func showWhiteListDomainsListView() {
        let vc = appCompositionRoot.createWhitelistDomainsListView()
        rootNavigationController?.present(vc, animated: true)
    }
    
    func initializeNavigation(in window: UIWindow) {
        let webViewController = appCompositionRoot.createWebViewController()
        rootNavigationController = UINavigationController(
            rootViewController: webViewController
        )
        rootNavigationController!.setNavigationBarHidden(true, animated: false)
        window.rootViewController = rootNavigationController
        
        initializeRulesManagerIfNeeded()
    }
    
    private func initializeRulesManagerIfNeeded() {
        guard NSClassFromString("XCTestCase") == nil else { return }
        guard appCompositionRoot.featureStore.isFeatureEnabled(.enhancedTrackingProtection) else { return }
        
        appCompositionRoot.wkContentRuleListManager.onInit()
    }
    
    func presentAlert(title: String, description: String) {
        let alertController = UIAlertController(
            title: title,
            message: description,
            preferredStyle: .alert
        )
        
        let accept = UIAlertAction(title: "Accept", style: .default) { _ in }
        alertController.addAction(accept)
        
        visibleViewController?.present(alertController, animated: true, completion: nil)
    }
    
    func dismissLastPresentedViewController() {
        visibleViewController?.dismiss(animated: true, completion: nil)
    }
}
