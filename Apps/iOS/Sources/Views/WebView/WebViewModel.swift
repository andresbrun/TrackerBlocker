import Combine
import WebKit
import os

enum WhitelistDomainState {
    case protected
    case unprotected
}

enum WebViewState {
    case empty
    case loaded
    case loading(Double)
    case error(WebViewError)
}

final class WebViewModel: NSObject {
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
    @Published var whitelistDomainState: WhitelistDomainState = .unprotected
    @Published var webViewState: WebViewState = .empty
    
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
    
    func updateEstimatedProgress(progress: Double) {
        webViewState = .loading(progress)
    }
    
    func tryToLoad(absoluteString: String?) -> Bool {
        guard let absoluteString else { return false }
        analyticsServices.trackEvent(.webViewTryToLoad(absoluteString))

        if let url = absoluteString.extractURLs().first {
            callbacksPublisher.send(.load(url))
            return true
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

    func showWhiteListDomainsListView() {
        analyticsServices.trackEvent(.webViewWhitelistDomainsViewTapped)
        navigator.showWhiteListDomainsListView(currentDomain: currentURL?.host())
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
    func webView(
        _ webView: WKWebView,
        didStartProvisionalNavigation navigation: WKNavigation!
    ) {
        navigationStartTime = Date()
        updateNavigationState(webView, state: .loading(webView.estimatedProgress))
    }

    func webView(
        _ webView: WKWebView,
        didFinish navigation: WKNavigation?
    ) {
        if let url = webView.url, let navigationStartTime {
            let loadTime = Int(Date().timeIntervalSince(navigationStartTime) * 1000)
            Logger.default.info("WebView did finish navigation in \(loadTime)ms to \(url)")
            analyticsServices.trackEvent(.webViewLoaded(url, loadTime))
        }
        updateNavigationState(webView, state: .loaded)
    }

    func webView(
        _ webView: WKWebView,
        didFail navigation: WKNavigation!,
        withError error: any Error
    ) {
        Logger.default.error("WebView did fail navigation with error: \(error)")
        updateNavigationState(
            webView,
            state: .error(.generic)
        )
    }
    
    func webView(
        _ webView: WKWebView,
        didFailProvisionalNavigation navigation: WKNavigation!,
        withError error: any Error
    ) {
        Logger.default.error("WebView did fail ProvisionalNavigation with error: \(error)")
        updateNavigationState(
            webView,
            state: .error(.generic)
        )
    }
    
    private func updateNavigationState(
        _ webView: WKWebView,
        state: WebViewState
    ) {
        currentURL = webView.url
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
        webViewState = state
        
        if shouldShowWhitelistUIControls {
            let whitelisted = whitelistDomainsManager.contains(webView.url)
            whitelistDomainState = whitelisted ? .unprotected : .protected
        }
    }
}
