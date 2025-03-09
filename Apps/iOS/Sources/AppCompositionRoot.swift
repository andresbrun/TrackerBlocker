import UIKit
import SwiftUI
import Combine
import WebKit

final class AppCompositionRoot {
    public unowned var rootNavigator: RootNavigator!
    
    // MARK: - Public
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
        let viewModel = WhitelistDomainsListViewModel(
            manager: whitelistDomainsManager,
            rootNavigator: rootNavigator,
            currentDomain: currentDomain,
            analyticsServices: analyticsServices
        )
        
        return UIHostingController(
            rootView: WhitelistDomainsListView(
                viewModel: viewModel
            )
        )
    }
    
    func initializeRulesManagerIfNeeded() {
        guard !AppEnvironment.isRunningTests else { return }
        guard featureStore.isFeatureEnabled(.enhancedTrackingProtection) else { return }
        
        wkContentRuleListManager.onInit()
    }
    
    // MARK: - Updates subjects
    private lazy var whitelistDomainsUpdates: CurrentValueSubject<[String], Never> = {
        CurrentValueSubject<[String], Never>([])
    }()
    
    private lazy var ruleListStateUpdates: CurrentValueSubject<RuleListStateUpdates?, Never> = {
        CurrentValueSubject<RuleListStateUpdates?, Never>(nil)
    }()
    
    // MARK: - Dependencies
    private lazy var analyticsServices: AnalyticsServices = {
        DefaultAnalyticsServices()
    }()
    
    private lazy var featureStore: FeatureStore = {
        FeatureStore(
            provider: FakeFeatureProvider()
        )
    }()
    
    private lazy var wkContentRuleListManager: WKContentRuleListManager = {
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
}
