import UIKit

import Combine
import WebKit
import Foundation

class AppCompositionRoot {
    private lazy var whitelistDomainsUpdates: CurrentValueSubject<[String], Never> = {
        CurrentValueSubject<[String], Never>([])
    }()
    
    private lazy var ruleListStateUpdates: CurrentValueSubject<RuleListStateUpdates?, Never> = {
        CurrentValueSubject<RuleListStateUpdates?, Never>(nil)
    }()
    
    lazy var wkContentRuleListManager: WKContentRuleListManager = {
        WKContentRuleListManager(
            userDefaults: UserDefaults.standard,
            ruleListStore: WKContentRuleListStore.default(),
            tdsAPI: DefaultTrackerDataSetAPI(),
            fileCache: DefaultTDSFileStorageCache(),
            whitelistDomainsUpdates: whitelistDomainsUpdates,
            ruleListStateUpdates: ruleListStateUpdates
        )
    }()
    
    func createWebViewController() -> WebViewController {
        WebViewController(nibName: nil, bundle: nil)
    }
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    private lazy var appCompositionRoot: AppCompositionRoot = .init()
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        
        let webViewController = appCompositionRoot.createWebViewController()
        let navigationController = UINavigationController(rootViewController: webViewController)
        navigationController.setNavigationBarHidden(true, animated: false)
        window?.rootViewController = navigationController
        
        // TODO: Change
        if NSClassFromString("XCTestCase") == nil {
            appCompositionRoot.wkContentRuleListManager.onInit()
        }
        
        window?.makeKeyAndVisible()
        
        return true
    }
}
