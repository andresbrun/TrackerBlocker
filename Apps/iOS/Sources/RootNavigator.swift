import Foundation
import UIKit

protocol RootNavigator: NSObject {
    func showWhiteListDomainsListView(currentDomain: String?)
    func initializeNavigation(in window: UIWindow)

    func presentAlert(title: String, description: String)
    
    func dismissLastPresentedViewController()
}

final class AppRootNavigator: NSObject, RootNavigator {
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
    
    func showWhiteListDomainsListView(
        currentDomain: String?
    ) {
        let vc = appCompositionRoot.createWhitelistDomainsListView(
            currentDomain: currentDomain
        )
        rootNavigationController?.present(vc, animated: true)
    }
    
    func initializeNavigation(in window: UIWindow) {
        let webViewController = appCompositionRoot.createWebViewController()
        rootNavigationController = UINavigationController(
            rootViewController: webViewController
        )
        rootNavigationController!.setNavigationBarHidden(true, animated: false)
        window.rootViewController = rootNavigationController
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
