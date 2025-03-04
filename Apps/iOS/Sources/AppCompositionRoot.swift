import UIKit
import SwiftUI
import Combine
import WebKit

class AppCompositionRoot {
    public unowned var rootNavigator: RootNavigator!
    
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
    
    private lazy var whitelistDomainsManager: WhitelistDomainsManager = {
        DefaultWhitelistDomainsManager(
            whitelistDomainsUpdates: whitelistDomainsUpdates
        )
    }()
    
    private func createUserContentController() -> UserContentController {
        UserContentController(
            ruleListStateUpdates: ruleListStateUpdates
        )
    }
    
    func createWebViewController() -> WebViewController {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController = createUserContentController()
        return WebViewController(
            configuration: configuration,
            whitelistDomainsManager: whitelistDomainsManager,
            ruleListStateUpdates: ruleListStateUpdates,
            navigator: rootNavigator
        )
    }
    
    func createWhitelistDomainsListView() -> UIViewController {
        UIHostingController(
            rootView: WhitelistDomainsListView(
                viewModel: .init(manager: self.whitelistDomainsManager)
            )
        )
    }
}
