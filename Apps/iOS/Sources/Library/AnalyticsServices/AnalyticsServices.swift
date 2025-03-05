import Foundation
import os

protocol EventTracking {
    func trackEvent(_ event: AnalyticsEvent)
}

enum AnalyticsEvent {
    case webViewTryToLoad(String)
    case webViewLoaded(URL, Int)
    case webViewGoForwardTapped
    case webViewGoBackTapped
    case webViewReloadTapped
    case webViewWhitelistDomainsViewTapped
    case webViewWhitelistDomainToggle(Bool, String)
    
    var name: String {
        switch self {
        case .webViewTryToLoad: "app-web_view_try_to_load"
        case .webViewLoaded: "app-web_view_loaded"
        case .webViewGoForwardTapped: "app-web_view_go_forward_tapped"
        case .webViewGoBackTapped: "app-web_view_go_back_tapped"
        case .webViewReloadTapped: "app-web_view_reload_tapped"
        case .webViewWhitelistDomainsViewTapped: "app-web_whitelist_domains_view_tapped"
        case .webViewWhitelistDomainToggle: "app-web_whitelist_toggle_tapped"
        }
    }
    
    var properties: [String: String] {
        switch self {
        case .webViewTryToLoad(let addressString):
            [
                "raw_string": addressString
            ]
        case .webViewLoaded(let url, let timeInMilliseconds):
            [
                "url": url.absoluteString,
                "duration_in_milliseconds": "\(timeInMilliseconds)"
            ]
        case .webViewWhitelistDomainToggle(let added, let domain):
            [
                "action": added ? "added" : "removed",
                "domain": domain
            ]
        default:
            [:]
        }
    }
}

class AnalyticsServices: EventTracking {
    private let logger = Logger.default
    
    func trackEvent(_ event: AnalyticsEvent) {
        logger.info("Event tracked: \(event.name) with properties: \(event.properties)")
    }
}
