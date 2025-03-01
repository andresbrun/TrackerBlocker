import UIKit
import WebKit

class WebViewController: UIViewController, WKNavigationDelegate, UITextFieldDelegate {
    
    private let webView = WKWebView()
    private let addressBar = UITextField()
    private let backButton = UIButton(type: .system)
    private let forwardButton = UIButton(type: .system)
    private let reloadButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadDefaultPage()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        webView.navigationDelegate = self
        
        // Configure address bar
        addressBar.placeholder = "Enter URL"
        addressBar.borderStyle = .roundedRect
        addressBar.delegate = self
        addressBar.autocapitalizationType = .none
        addressBar.autocorrectionType = .no
        addressBar.returnKeyType = .go
        
        // Configure buttons
        backButton.setTitle("←", for: .normal)
        backButton.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        
        forwardButton.setTitle("→", for: .normal)
        forwardButton.addTarget(self, action: #selector(goForward), for: .touchUpInside)
        
        reloadButton.setTitle("⟳", for: .normal)
        reloadButton.addTarget(self, action: #selector(reloadPage), for: .touchUpInside)
        
        // Toolbar
        let toolbar = UIStackView(arrangedSubviews: [backButton, forwardButton, reloadButton])
        toolbar.axis = .horizontal
        toolbar.distribution = .equalSpacing
        
        // Layout
        let stackView = UIStackView(arrangedSubviews: [addressBar, webView, toolbar])
        stackView.axis = .vertical
        stackView.spacing = 8
        view.addSubview(stackView)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            
            addressBar.heightAnchor.constraint(equalToConstant: 40),
            toolbar.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func loadDefaultPage() {
        let url = URL(string: "https://www.apple.com")!
        webView.load(URLRequest(url: url))
        addressBar.text = url.absoluteString
    }
    
    // MARK: - Actions
    
    @objc private func goBack() {
        if webView.canGoBack {
            webView.goBack()
        }
    }
    
    @objc private func goForward() {
        if webView.canGoForward {
            webView.goForward()
        }
    }
    
    @objc private func reloadPage() {
        webView.reload()
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let text = textField.text, let url = URL(string: text.hasPrefix("http") ? text : "https://\(text)") else {
            return false
        }
        webView.load(URLRequest(url: url))
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
        addressBar.text = webView.url?.absoluteString
        backButton.isEnabled = webView.canGoBack
        forwardButton.isEnabled = webView.canGoForward
    }
}
