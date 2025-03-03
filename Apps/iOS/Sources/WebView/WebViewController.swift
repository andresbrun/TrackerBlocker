import UIKit
import WebKit

class WebViewController: UIViewController {
    
    // MARK: - Constants
    private let stackViewSpacing: CGFloat = 8.0
    private let addressBarHeight: CGFloat = 40.0
    private let toolbarHeight: CGFloat = 44.0
    private let keyboardAnimationDuration: TimeInterval = 0.3
    private let scrollAnimationDuration: TimeInterval = 0.3
    private let padding: CGFloat = 8.0
    private let minThreasholdToHideBottomView: CGFloat = 100.0
    
    // MARK: - Dependencies
    private let configuration: WKWebViewConfiguration
    
    // MARK: - State
    private var lastContentOffset: CGFloat = 0
    private var isKeyboardVisible: Bool = false
    private var mainStackViewBottomConstraint: NSLayoutConstraint?
    
    // MARK: - UI components
    private lazy var webView: WKWebView = {
        let webView = WKWebView(
            frame: view.bounds,
            configuration: configuration
        )
        webView.navigationDelegate = self
        webView.scrollView.delegate = self
        return webView
    }()
    
    private lazy var addressBar: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter URL"
        textField.borderStyle = .roundedRect
        textField.delegate = self
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.returnKeyType = .go
        return textField
    }()
    
    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("←", for: .normal)
        button.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        return button
    }()
    
    private lazy var forwardButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("→", for: .normal)
        button.addTarget(self, action: #selector(goForward), for: .touchUpInside)
        return button
    }()
    
    private lazy var reloadButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("⟳", for: .normal)
        button.addTarget(self, action: #selector(reloadPage), for: .touchUpInside)
        return button
    }()
    
    private lazy var toolbar: UIStackView = {
        let view = UIStackView(arrangedSubviews: [backButton, forwardButton, reloadButton])
        view.axis = .horizontal
        view.distribution = .equalSpacing
        view.heightAnchor.constraint(equalToConstant: toolbarHeight).isActive = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var whiteListButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("WhiteList", for: .normal)
        button.addTarget(self, action: #selector(whiteListAction), for: .touchUpInside)
        return button
    }()
    
    private lazy var addressBarStackView: UIStackView = {
        let view = UIStackView(
            arrangedSubviews: [
                whiteListButton,
                addressBar
            ]
        )
        view.axis = .horizontal
        view.spacing = stackViewSpacing
        view.heightAnchor.constraint(equalToConstant: addressBarHeight).isActive = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var addressBarAndToolbarView: UIView = {
        let view = UIStackView(
            arrangedSubviews: [
                addressBarStackView,
                toolbar
            ]
        )
        view.axis = .vertical
        view.spacing = padding
        view.translatesAutoresizingMaskIntoConstraints = false
        return view.padding(left: padding, right: padding)
    }()
    
    private lazy var mainStackView: UIStackView = {
        let view = UIStackView(
            arrangedSubviews: [
                webView,
                progressBar,
                addressBarAndToolbarView
            ]
        )
        view.axis = .vertical
        view.spacing = stackViewSpacing
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var progressBar: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        return progressView
    }()
    
    init(configuration: WKWebViewConfiguration) {
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        removeObservers()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        loadDefaultPage()
        setupKeyboardObservers()
        setupEstimatedProgressObserver()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        view.addSubview(mainStackView)
        
        mainStackViewBottomConstraint = mainStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainStackViewBottomConstraint!
        ])
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    private func setupEstimatedProgressObserver() {
        webView.addObserver(
            self,
            forKeyPath: #keyPath(WKWebView.estimatedProgress),
            options: .new,
            context: nil
        )
    }
    
    private func removeObservers() {
        NotificationCenter.default.removeObserver(self)
        webView.removeObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress))
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard addressBar.isFirstResponder else { return }
        
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let offset = view.safeAreaInsets.bottom - keyboardFrame.height
            mainStackViewBottomConstraint?.constant = offset
            isKeyboardVisible = true
            let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? keyboardAnimationDuration
            UIView.animate(withDuration: duration) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    @objc private func keyboardWillHide(_ notification: Notification) {
        mainStackViewBottomConstraint?.constant = 0
        isKeyboardVisible = false
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? keyboardAnimationDuration
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func loadDefaultPage() {
        let url = URL(string: "https://www.duckduckgo.com")!
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
    
    @objc private func whiteListAction() {
        // Implement the action for the WhiteList button
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == #keyPath(WKWebView.estimatedProgress) {
            progressBar.progress = Float(webView.estimatedProgress)
            progressBar.isHidden = webView.estimatedProgress == 1
        }
    }
}

extension WebViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let text = textField.text, let url = URL(string: text.hasPrefix("http") ? text : "https://\(text)") else {
            return false
        }
        webView.load(URLRequest(url: url))
        textField.resignFirstResponder()
        return true
    }
}

extension WebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
        updateNavigationUI()
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation?) {
        updateNavigationUI()
    }
    
    private func updateNavigationUI() {
        addressBar.text = webView.url?.absoluteString
        backButton.isEnabled = webView.canGoBack
        forwardButton.isEnabled = webView.canGoForward
    }
}

extension WebViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isKeyboardVisible else { return }
        let currentOffset = scrollView.contentOffset.y
        guard currentOffset > minThreasholdToHideBottomView else { return }
        
        if currentOffset < lastContentOffset {
            mainStackViewBottomConstraint?.constant = 0
        } else if currentOffset > lastContentOffset {
            mainStackViewBottomConstraint?.constant = addressBarAndToolbarView.frame.height + view.safeAreaInsets.bottom
        }
        
        lastContentOffset = currentOffset
        
        UIView.animate(withDuration: scrollAnimationDuration) {
            self.view.layoutIfNeeded()
        }
    }
}
