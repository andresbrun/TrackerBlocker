import SwiftUI
import Combine

class WhitelistDomainsListViewModel: ObservableObject {
    // MARK: - Dependencies
    private var manager: WhitelistDomainsManager
    private let rootNavigator: RootNavigator
    
    // MARK: - State
    private var cancellables = Set<AnyCancellable>()
    @Published var domains: [String] = []
    
    init(
        manager: WhitelistDomainsManager,
        rootNavigator: RootNavigator
    ) {
        self.manager = manager
        self.rootNavigator = rootNavigator
        subscribeToDomainsListUpdates()
    }
    
    // MARK: - Public
    var navigationBarTitle: String {
        IOSStrings.Whitelistdomainsview.NavigationBar.title
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
            manager.add(host)
            return true
        }
    }

    func removeDomain(at offsets: IndexSet) {
        for index in offsets {
            manager.remove(domains[index])
        }
    }
    
    func dismissView() {
        rootNavigator.dismissLastPresentedViewController()
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
        let urlString = domain.hasPrefix("http://") || domain.hasPrefix("https://") ? domain : "https://\(domain)"
        guard let urlComponents = URLComponents(string: urlString) else { return nil }
        return urlComponents.host
    }
}
