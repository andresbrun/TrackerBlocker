import SwiftUI

struct WhitelistDomainsListView: View {
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
                    }
                }
            }
        }
    }
    
    private func createItemView(with domain: String) -> some View {
        HStack {
            Image(systemName: "globe")
                .foregroundColor(.blue)
            Text(domain)
        }
    }
    
    private func createNewDomainItemView() -> some View {
        HStack(spacing: 8) {
            Image(systemName: "plus.circle")
                .foregroundColor(.blue)
            TextField("Enter new domain", text: $newDomain)
                .keyboardType(.URL)
                .autocapitalization(.none)
                .onSubmit {
                    withAnimation {
                        addDomain()
                    }
                }
        }
    }

    private func addDomain() {
        guard viewModel.addDomain(newDomain) else { return }
        newDomain = ""
    }

    private func dismissView() {
        viewModel.dismissView()
    }
}
