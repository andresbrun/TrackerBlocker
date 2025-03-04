import Foundation
import UIKit

protocol RootNavigator: NSObject {
    func showWhiteListDomainsListView()
    func initializeNavigation(in window: UIWindow)
}

class AppRootNavigator: NSObject, RootNavigator {
    private let appCompositionRoot: AppCompositionRoot
    private var rootNavigationController: UINavigationController?
    
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
        if NSClassFromString("XCTestCase") == nil {
            appCompositionRoot.wkContentRuleListManager.onInit()
        }
    }
}
