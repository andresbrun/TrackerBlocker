import SwiftUI

struct WhitelistDomainsListView: View {
    // MARK: - State
    @StateObject var viewModel: WhitelistDomainsListViewModel
    @State private var newDomain: String = ""

    // MARK: - View Builders
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
                    closeButton()
                }
            }
        }
    }
    
    private func createItemView(with domain: String) -> some View {
        HStack(spacing: Dimensions.Spacing.Default) {
            Image(systemName: "globe")
            Text(domain)
        }
        .foregroundColor(IOSAsset.Colors.textColor.swiftUIColor)
    }
    
    private func createNewDomainItemView() -> some View {
        HStack(spacing: Dimensions.Spacing.Default) {
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
    
    private func closeButton() -> some View {
        Button(action: {
            viewModel.dismissView()
        }) {
            Image(systemName: "xmark")
                .foregroundColor(IOSAsset.Colors.textColor.swiftUIColor)
        }
    }

    // MARK: - Private
    private func addDomain() {
        guard viewModel.addDomain(newDomain) else { return }
        newDomain = ""
    }
}
