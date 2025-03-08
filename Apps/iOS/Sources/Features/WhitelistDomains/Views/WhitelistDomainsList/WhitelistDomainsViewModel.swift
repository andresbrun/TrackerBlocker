import SwiftUI
import Combine

final class WhitelistDomainsListViewModel: ObservableObject {
    // MARK: - Dependencies
    private var manager: WhitelistDomainsManager
    private let rootNavigator: RootNavigator
    private let analyticsServices: AnalyticsServices
    
    // MARK: - State
    private var cancellables = Set<AnyCancellable>()
    @Published var domains: [String] = [] {
        didSet {
            guard let currentDomain else { return }
            isCurrentDomainWhitelisted = domains.contains(currentDomain)
        }
    }
    @Published var currentDomain: String?
    @Published var isCurrentDomainWhitelisted: Bool
    
    init(
        manager: WhitelistDomainsManager,
        rootNavigator: RootNavigator,
        currentDomain: String?,
        analyticsServices: AnalyticsServices
    ) {
        self.manager = manager
        self.rootNavigator = rootNavigator
        self.currentDomain = currentDomain
        self.analyticsServices = analyticsServices
        if let currentDomain {
            self.isCurrentDomainWhitelisted = manager.contains(currentDomain)
        } else {
            self.isCurrentDomainWhitelisted = false
        }
        subscribeToDomainsListUpdates()
    }
    
    // MARK: - Public
    var navigationBarTitle: String {
        IOSStrings.Whitelistdomainsview.NavigationBar.title
    }

    var currentWebsiteTitle: String {
        IOSStrings.Whitelistdomainsview.Section.currentWebsite
    }

    var allWebsitesTitle: String {
        IOSStrings.Whitelistdomainsview.Section.allWebsites
    } 
    
    func addDomain(_ domain: String) -> Bool {
        guard let host = normalizedDomain(domain) else {
            rootNavigator.presentAlert(
                title: IOSStrings.Whitelistdomainsview.Alert.InvalidDomain.title,
                description: IOSStrings.Whitelistdomainsview.Alert.InvalidDomain.description(domain)
            )
            return false
        }
        
        if domains.contains(host) {
            rootNavigator.presentAlert(
                title: IOSStrings.Whitelistdomainsview.Alert.DuplicatedDomain.title,
                description: IOSStrings.Whitelistdomainsview.Alert.DuplicatedDomain.description(domain)
            )
            return false
        } else {
            analyticsServices.trackEvent(.whitelistAddedDomain(host))
            manager.add(host)
            return true
        }
    }

    func removeDomain(at offsets: IndexSet) {
        for index in offsets {
            let domain = domains[index]
            analyticsServices.trackEvent(.whitelistRemovedDomain(domain))
            manager.remove(domain)
        }
    }
    
    func dismissView() {
        rootNavigator.dismissLastPresentedViewController()
    }
    
    func toggleCurrentDomain(enable: Bool) {
        guard let currentDomain else { return }
        
        if enable {
            manager.add(currentDomain)
        } else {
            manager.remove(currentDomain)
        }
        analyticsServices.trackEvent(.whitelistCurrentDomainToggle(enable, currentDomain))
    }
    
    // MARK: - Private
    private func subscribeToDomainsListUpdates() {
        manager.updates
            .receive(on: DispatchQueue.main)
            .sink { domains in
                self.domains = domains
            }
            .store(in: &cancellables)
    }

    private func normalizedDomain(_ domain: String) -> String? {
        domain.extractURLs().first?.host()
    }
}
