import SwiftUI
import Combine

final class WhitelistDomainsListViewModel: ObservableObject {
    // MARK: - Dependencies
    private var manager: WhitelistDomainsManager
    private let rootNavigator: RootNavigator
    private let analyticsServices: EventTracking
    
    // MARK: - State
    private var cancellables = Set<AnyCancellable>()
    @Published var domains: [String] = [] {
        didSet {
            guard let currentDomain else { return }
            isCurrentDomainProtected = !domains.contains(currentDomain)
        }
    }
    @Published var currentDomain: String?
    @Published var isCurrentDomainProtected: Bool
    
    init(
        manager: WhitelistDomainsManager,
        rootNavigator: RootNavigator,
        currentDomain: String?,
        analyticsServices: EventTracking
    ) {
        self.manager = manager
        self.rootNavigator = rootNavigator
        self.currentDomain = currentDomain
        self.analyticsServices = analyticsServices
        if let currentDomain {
            self.isCurrentDomainProtected = !manager.contains(currentDomain)
        } else {
            self.isCurrentDomainProtected = true
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
    
    var protectionsText: AttributedString {
        let markdown = isCurrentDomainProtected ? IOSStrings.Whitelistdomainsview.Protections.enabled : IOSStrings.Whitelistdomainsview.Protections.disabled
        // Force try because is a localizable string
        return try! AttributedString(markdown: markdown)
    }
    
    var protectionsIcon: Image {
        isCurrentDomainProtected ? IOSAsset.Assets.icProtectionEnabled.swiftUIImage : IOSAsset.Assets.icProtectionDisabled.swiftUIImage
    }
    
    var createNewDomainPlaceholder: String {
        IOSStrings.Whitelistdomainsview.NewDomainField.placeholder
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
    
    func toggleCurrentDomain(enableProtection: Bool) {
        guard let currentDomain else { return }
        
        if enableProtection {
            manager.remove(currentDomain)
        } else {
            manager.add(currentDomain)
        }
        analyticsServices.trackEvent(.whitelistCurrentDomainToggle(!enableProtection, currentDomain))
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
