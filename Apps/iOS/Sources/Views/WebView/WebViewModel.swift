import Combine
import WebKit
import os

class WebViewModel: NSObject {
    // MARK: - Dependencies
    private let whitelistDomainsManager: WhitelistDomainsManager
    private let ruleListStateUpdates: CurrentValueSubject<RuleListStateUpdates?, Never>
    private unowned let navigator: RootNavigator
    private let featureStore: FeatureStore
    private let analyticsServices: AnalyticsServices
    
    // MARK: - State
    @Published var currentURL: URL?
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var estimatedProgress: Double = 0.0
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: VC communication
    enum Callbacks {
        case load(URL)
        case goBack
        case goForward
    }
    let callbacksPublisher = PassthroughSubject<Callbacks, Never>()
    
    init(
        whitelistDomainsManager: WhitelistDomainsManager,
        ruleListStateUpdates: CurrentValueSubject<RuleListStateUpdates?, Never>,
        navigator: RootNavigator,
        featureStore: FeatureStore,
        analyticsServices: AnalyticsServices
    ) {
        self.whitelistDomainsManager = whitelistDomainsManager
        self.ruleListStateUpdates = ruleListStateUpdates
        self.navigator = navigator
        self.featureStore = featureStore
        self.analyticsServices = analyticsServices
        
        super.init()
        
        subscribeToRuleListStateUpdates()
    }
    
    func loadDefaultPage() {
        let url = URL(string: "https://www.duckduckgo.com")!
        callbacksPublisher.send(.load(url))
    }
    
    func tryToLoad(absoluteString: String?) -> Bool {
        // TODO: Address Sanitizer
        guard
            let absoluteString = absoluteString,
            let url = URL(string: absoluteString.hasPrefix("http") ? absoluteString : "https://\(absoluteString)")
        else {
            return false
        }
        
        callbacksPublisher.send(.load(url))
        return true
    }
    
    func reloadCurrentPage() {
        guard let currentURL = currentURL else { return }
        callbacksPublisher.send(.load(currentURL))
    }
    
    func goBack() {
        callbacksPublisher.send(.goBack)
    }
    
    func goForward() {
        callbacksPublisher.send(.goForward)
    }
    
    func toggleWhitelistDomain(for host: String?) {
        guard let host else { return }
        
        if whitelistDomainsManager.getAll().contains(host) {
            Logger.default.info("Removing \(host) from whitelist")
            analyticsServices.trackEvent(.webViewWhitelistDomainToggle(false, host))
            whitelistDomainsManager.remove(host)
        } else {
            Logger.default.info("Adding \(host) in whitelist")
            analyticsServices.trackEvent(.webViewWhitelistDomainToggle(true, host))
            whitelistDomainsManager.add(host)
        }
    }
    
    func showWhiteListDomainsListView() {
        navigator.showWhiteListDomainsListView()
    }
    
    private func subscribeToRuleListStateUpdates() {
        ruleListStateUpdates
            .delay(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] stateUpdates in
                guard let self else { return }
                
                switch stateUpdates?.reason {
                case .whitelistUpdated(let added, let removed):
                    guard
                        let currentURL = self.currentURL,
                        let hostLoaded = currentURL.host
                    else {
                        return
                    }
                    if (added + removed).contains(hostLoaded) {
                        callbacksPublisher.send(.load(currentURL))
                    }
                    
                default:
                    break
                }
            }.store(in: &cancellables)
    }
}

extension WebViewModel: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
        updateNavigationState(webView)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation?) {
        updateNavigationState(webView)
    }
    
    private func updateNavigationState(_ webView: WKWebView) {
        currentURL = webView.url
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
    }
}
