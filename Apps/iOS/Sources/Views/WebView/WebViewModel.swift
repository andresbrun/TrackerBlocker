import Combine
import WebKit
import os

enum WhitelistDomainState {
    case protected
    case unprotected
}

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
    @Published var whitelistDomainState: WhitelistDomainState = .unprotected
    
    private var navigationStartTime: Date?
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
    
    // MARK: - Actions
    func loadDefaultPage() {
        let url = URL(string: Constants.URL.DefaultSearchEngine)!
        callbacksPublisher.send(.load(url))
    }
    
    func tryToLoad(absoluteString: String?) -> Bool {
        guard let absoluteString else { return false }
        analyticsServices.trackEvent(.webViewTryToLoad(absoluteString))
        // TODO: Address Sanitizer
        if let url = URL(string: absoluteString.hasPrefix("http") ? absoluteString : "https://\(absoluteString)") {
            callbacksPublisher.send(.load(url))
        } else if !absoluteString.isEmpty {
            let searchURL = createSearchURL(for: absoluteString)
            callbacksPublisher.send(.load(searchURL))
            return true
        }
        
        return false
    }
    
    func reloadCurrentPage() {
        analyticsServices.trackEvent(.webViewReloadTapped)
        guard let currentURL else { return }
        callbacksPublisher.send(.load(currentURL))
    }
    
    func goBack() {
        analyticsServices.trackEvent(.webViewGoBackTapped)
        callbacksPublisher.send(.goBack)
    }
    
    func goForward() {
        analyticsServices.trackEvent(.webViewGoForwardTapped)
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
        analyticsServices.trackEvent(.webViewWhitelistDomainsViewTapped)
        navigator.showWhiteListDomainsListView()
    }
    
    // MARK: - Accessors
    var shouldShowWhitelistUIControls: Bool {
        featureStore.isFeatureEnabled(.enhancedTrackingProtection)
    }
    
    // MARK: - Private
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
    
    private func createSearchURL(for string: String) -> URL {
        var components = URLComponents(string: Constants.URL.DefaultSearchEngine)!
        components.queryItems = [URLQueryItem(name: "q", value: string)]
        return components.url!
    }
}

extension WebViewModel: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        navigationStartTime = Date()
        updateNavigationState(webView)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
        if let url = webView.url, let navigationStartTime {
            let loadTime = Int(Date().timeIntervalSince(navigationStartTime) * 1000)
            Logger.default.info("WebView did finish navigation in \(loadTime)ms to \(url)")
            analyticsServices.trackEvent(.webViewLoaded(url, loadTime))
        }
        updateNavigationState(webView)
    }

    private func updateNavigationState(_ webView: WKWebView) {
        currentURL = webView.url
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
        if shouldShowWhitelistUIControls {
            let whitelisted = whitelistDomainsManager.contains(webView.url)
            whitelistDomainState = whitelisted ? .unprotected : .protected
        }
    }
}

