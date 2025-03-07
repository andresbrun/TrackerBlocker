import UIKit
import SwiftUI
import Combine
import WebKit

final class AppCompositionRoot {
    public unowned var rootNavigator: RootNavigator!
    
    private lazy var whitelistDomainsUpdates: CurrentValueSubject<[String], Never> = {
        CurrentValueSubject<[String], Never>([])
    }()
    
    private lazy var ruleListStateUpdates: CurrentValueSubject<RuleListStateUpdates?, Never> = {
        CurrentValueSubject<RuleListStateUpdates?, Never>(nil)
    }()
    
    private lazy var analyticsServices: AnalyticsServices = {
        AnalyticsServices()
    }()
    
    lazy var featureStore: FeatureStore = {
        FeatureStore(
            provider: FakeFeatureProvider()
        )
    }()
    
    lazy var wkContentRuleListManager: WKContentRuleListManager = {
        WKContentRuleListManager(
            userDefaults: UserDefaults.standard,
            ruleListStore: WKContentRuleListStore.default(),
            tdsAPI: DefaultTrackerDataSetAPI(),
            fileCache: DefaultTDSFileStorageCache(),
            whitelistDomainsUpdates: whitelistDomainsUpdates,
            ruleListStateUpdates: ruleListStateUpdates,
            analyticsServices: analyticsServices
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
        
        let webViewModel = WebViewModel(
            whitelistDomainsManager: whitelistDomainsManager,
            ruleListStateUpdates: ruleListStateUpdates,
            navigator: rootNavigator,
            featureStore: featureStore,
            analyticsServices: analyticsServices
        )
        
        return WebViewController(
            configuration: configuration,
            viewModel: webViewModel
        )
    }
    
    func createWhitelistDomainsListView(
        currentDomain: String?
    ) -> UIViewController {
        UIHostingController(
            rootView: WhitelistDomainsListView(
                viewModel: .init(
                    manager: self.whitelistDomainsManager,
                    rootNavigator: self.rootNavigator,
                    currentDomain: currentDomain,
                    analyticsServices: self.analyticsServices
                )
            )
        )
    }
}
