import SwiftUI

struct WhitelistDomainsListView: View {
    // MARK: - Constants
    private let InternalPadding = 8.0
    
    // MARK: - State
    @StateObject var viewModel: WhitelistDomainsListViewModel
    @State private var newDomain: String = ""

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.domains, id: \.self) { domain in
                    createItemView(with: domain)
                }
                .onDelete(perform: { indexSet in
                    withAnimation {
                        viewModel.removeDomain(at: indexSet)
                    }
                })
                createNewDomainItemView()
            }
            .navigationTitle(viewModel.navigationBarTitle)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        dismissView()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(IOSAsset.Colors.textColor.swiftUIColor)
                    }
                }
            }
        }
    }
    
    private func createItemView(with domain: String) -> some View {
        HStack(spacing: InternalPadding) {
            Image(systemName: "globe")
            Text(domain)
        }
        .foregroundColor(IOSAsset.Colors.textColor.swiftUIColor)
    }
    
    private func createNewDomainItemView() -> some View {
        HStack(spacing: InternalPadding) {
            Image(systemName: "plus.circle")
            TextField("Enter new domain", text: $newDomain)
                .keyboardType(.URL)
                .autocapitalization(.none)
                .onSubmit {
                    withAnimation {
                        addDomain()
                    }
                }
        }
        .foregroundColor(IOSAsset.Colors.textColor.swiftUIColor)
    }

    private func addDomain() {
        guard viewModel.addDomain(newDomain) else { return }
        newDomain = ""
    }

    private func dismissView() {
        viewModel.dismissView()
    }
}
