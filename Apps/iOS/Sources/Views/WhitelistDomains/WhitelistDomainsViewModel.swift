import SwiftUI
import Combine

class WhitelistDomainsListViewModel: ObservableObject {
    @Published var domains: [String] = []
    private var manager: WhitelistDomainsManager
    private let rootNavigator: RootNavigator
    private var cancellables = Set<AnyCancellable>()
    
    var navigationBarTitle: String {
        IOSStrings.Whitelistdomainsview.NavigationBar.title
    }
    
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
