import SwiftUI
import Combine

class WhitelistDomainsListViewModel: ObservableObject {
    @Published var domains: [String] = []
    private var manager: WhitelistDomainsManager
    private let rootNavigator: RootNavigator
    private var cancellables = Set<AnyCancellable>()
    
    init(
        manager: WhitelistDomainsManager,
        rootNavigator: RootNavigator
    ) {
        self.manager = manager
        self.rootNavigator = rootNavigator
        subscribeToDomainsListUpdates()
    }
    
    private func subscribeToDomainsListUpdates() {
        manager.updates
            .receive(on: DispatchQueue.main)
            .sink { domains in
                self.domains = domains
            }
            .store(in: &cancellables)
    }

    func addDomain(_ domain: String) -> Bool {
        guard let host = normalizedDomain(domain) else {
            rootNavigator.presentAlert(
                title: "Invalid Domain",
                description: "The domain '\(domain)' is not valid."
            )
            return false
        }
        
        if domains.contains(host) {
            rootNavigator.presentAlert(
                title: "Duplicated Domain",
                description: "The domain '\(host)' is already in the list."
            )
            return false
        } else {
            Task {
                await manager.add(host)
            }
            return true
        }
    }

    func removeDomain(at offsets: IndexSet) {
        Task {
            for index in offsets {
                await manager.remove(domains[index])
            }
        }
    }
    
    func dismissView() {
        rootNavigator.dismissLastPresentedViewController()
    }
    
    private func normalizedDomain(_ domain: String) -> String? {
        let urlString = domain.hasPrefix("http://") || domain.hasPrefix("https://") ? domain : "https://\(domain)"
        guard let urlComponents = URLComponents(string: urlString) else { return nil }
        return urlComponents.host
    }
}
