import SwiftUI
import Combine

struct WhitelistDomainsListView: View {
    @StateObject var viewModel: WhitelistDomainsViewModel
    @State private var newDomain: String = ""

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Enter domain", text: $newDomain)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    Button(action: {
                        guard !newDomain.isEmpty else { return }
                        viewModel.addDomain(newDomain)
                        newDomain = ""
                    }) {
                        Text("Add")
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()

                List {
                    ForEach(viewModel.domains, id: \.self) { domain in
                        Text(domain)
                    }
                    .onDelete(perform: viewModel.removeDomain)
                }
            }
            .navigationTitle("Whitelist Domains")
            .onAppear {
                Task {
                    await viewModel.loadDomains()
                }
            }
        }
    }
}

class WhitelistDomainsViewModel: ObservableObject {
    @Published var domains: [String] = []
    private var manager: WhitelistDomainsManager
    private var cancellables = Set<AnyCancellable>()

    init(
        manager: WhitelistDomainsManager
    ) {
        self.manager = manager
    }
    
    func loadDomains() async {
        domains = await manager.getAll()
    }

    func addDomain(_ domain: String) {
        Task {
            await manager.add(domain)
        }
    }

    func removeDomain(at offsets: IndexSet) {
        Task {
            for index in offsets {
                await manager.remove(domains[index])
            }
        }
    }
}

