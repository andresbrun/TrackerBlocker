import SwiftUI

struct WhitelistDomainsListView: View {
    // MARK: - State
    @StateObject var viewModel: WhitelistDomainsListViewModel
    @State private var newDomain: String = ""

    // MARK: - View Builders
    var body: some View {
        NavigationView {
            List {
                if let currentDomain = viewModel.currentDomain {
                    Section {
                        createCurrentItemView(with: currentDomain)
                    }
                    header: {
                        Text(viewModel.currentWebsiteTitle)
                    }
                }

                Section {
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
                header: {
                    Text(viewModel.allWebsitesTitle)
                }
            }
            .navigationTitle(viewModel.navigationBarTitle)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    closeButton()
                }
            }
        }
    }
    
    private func createItemView(
        with domain: String
    ) -> some View {
        HStack(spacing: Dimensions.Spacing.Default) {
            Image(systemName: "globe")
            Text(domain)
        }
        .foregroundColor(IOSAsset.Colors.textColor.swiftUIColor)
        .accessibilityElement(children: .combine)
    }
    
    private func createCurrentItemView(
        with currentDomain: String
    ) -> some View {
        HStack(spacing: Dimensions.Spacing.Default) {
            viewModel.protectionsIcon
            Text(viewModel.protectionsText)
        
            Spacer()
            Toggle("", isOn: $viewModel.isCurrentDomainProtected)
                .frame(width: Dimensions.Size.ToggleWidth)
                .onChange(of: viewModel.isCurrentDomainProtected) { _, enable in
                    viewModel.toggleCurrentDomain(enableProtection: enable)
                }
                .accessibilityLabel(IOSStrings.Webviewcontroller.ToggleWhitelistDomainButton.accessibilityLabel)
                .accessibilityHint(IOSStrings.Webviewcontroller.ToggleWhitelistDomainButton.accessibilityHint)
        }
        .foregroundColor(IOSAsset.Colors.textColor.swiftUIColor)
    }
    
    private func createNewDomainItemView() -> some View {
        HStack(spacing: Dimensions.Spacing.Default) {
            Image(systemName: "plus.circle")
            TextField(viewModel.createNewDomainPlaceholder, text: $newDomain)
                .keyboardType(.URL)
                .autocapitalization(.none)
                .onSubmit {
                    withAnimation {
                        addDomain()
                    }
                }
        }
        .foregroundColor(IOSAsset.Colors.textColor.swiftUIColor)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(IOSStrings.Whitelistdomainsview.NewDomainField.accessibilityLabel)
        .accessibilityHint(IOSStrings.Whitelistdomainsview.NewDomainField.accessibilityHint)
    }
    
    private func closeButton() -> some View {
        Button(action: {
            viewModel.dismissView()
        }) {
            Image(systemName: "xmark")
                .foregroundColor(IOSAsset.Colors.textColor.swiftUIColor)
        }
        .accessibilityLabel(IOSStrings.Whitelistdomainsview.CloseButton.accessibilityLabel)
        .accessibilityHint(IOSStrings.Whitelistdomainsview.CloseButton.accessibilityHint)
    }

    // MARK: - Private
    private func addDomain() {
        guard viewModel.addDomain(newDomain) else { return }
        newDomain = ""
    }
}
