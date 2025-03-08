import Foundation
import os

protocol AnalyticsServices {
    func trackEvent(_ event: AnalyticsEvent)
}

enum AnalyticsEvent {
    // WebView
    case webViewTryToLoad(String)
    case webViewLoaded(URL, Int)
    case webViewGoForwardTapped
    case webViewGoBackTapped
    case webViewReloadTapped
    case webViewWhitelistDomainsViewTapped
    // Whitelist
    case whitelistCurrentDomainToggle(Bool, String)
    case whitelistAddedDomain(String)
    case whitelistRemovedDomain(String)
    // ContentRule Manager
    case contentRuleListError(_ errorType: String, _ details: String)
    case contentRuleListCompileSucceded(Double)
    
    var name: String {
        switch self {
        case .webViewTryToLoad: "app-web_view_try_to_load"
        case .webViewLoaded: "app-web_view_loaded"
        case .webViewGoForwardTapped: "app-web_view_go_forward_tapped"
        case .webViewGoBackTapped: "app-web_view_go_back_tapped"
        case .webViewReloadTapped: "app-web_view_reload_tapped"
        case .webViewWhitelistDomainsViewTapped: "app-web_whitelist_domains_view_tapped"
        case .whitelistCurrentDomainToggle: "app-whitelist_domains_view_current_domain_toggle"
        case .whitelistAddedDomain: "app-whitelist_domains_view_added_domain"
        case .whitelistRemovedDomain: "app-whitelist_domains_view_removed_domain"
        case .contentRuleListError: "app-content_rule_list_error"
        case .contentRuleListCompileSucceded: "app-content_rule_compile_succeded"
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
        case .whitelistCurrentDomainToggle(let added, let domain):
            [
                "action": added ? "added" : "removed",
                "domain": domain
            ]
        case .whitelistAddedDomain(let domain), .whitelistRemovedDomain(let domain):
            [
                "domain": domain
            ]
        case .contentRuleListError(let errorType, let details):
            [
                "error_type": errorType,
                "details": details
            ]
        case .contentRuleListCompileSucceded(let duration):
            [
                "duration": "\(duration)"
            ]
        default:
            [:]
        }
    }
}

class DefaultAnalyticsServices: AnalyticsServices {
    private let logger = Logger.default
    
    func trackEvent(_ event: AnalyticsEvent) {
        logger.info("Event tracked: \(event.name) with properties: \(event.properties)")
    }
}
