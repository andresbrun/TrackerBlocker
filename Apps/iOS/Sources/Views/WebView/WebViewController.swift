import UIKit
import WebKit
import Combine
import os

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
    private let viewModel: WebViewModel
    private let configuration: WKWebViewConfiguration
    
    // MARK: - State
    private var lastContentOffset: CGFloat = 0
    private var isKeyboardVisible: Bool = false
    private var mainStackViewBottomConstraint: NSLayoutConstraint?
    private var observer: NSKeyValueObservation?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UI components
    private lazy var mainStackView: UIStackView = {
        let view = UIStackView(
            arrangedSubviews: [
                webView,
                progressBar,
                addressBarAndToolbarView
            ]
        )
        view.axis = .vertical
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var webView: WKWebView = {
        let webView = WKWebView(
            frame: view.bounds,
            configuration: configuration
        )
        webView.navigationDelegate = viewModel
        webView.scrollView.delegate = self
        return webView
    }()
    
    private lazy var progressBar: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .default)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.accessibilityLabel = IOSStrings.Webviewcontroller.ProgressBar.accessibilityLabel
        progressView.accessibilityTraits = .updatesFrequently
        return progressView
    }()
    
    private lazy var addressBarAndToolbarView: UIView = {
        let view = UIStackView(
            arrangedSubviews: [
                addressBar,
                toolbar
            ]
        )
        view.axis = .vertical
        view.spacing = padding
        view.translatesAutoresizingMaskIntoConstraints = false
        let wrappedView = view.padding(all: padding)
        wrappedView.backgroundColor = IOSAsset.Colors.primaryBackgroundColor.color
        return wrappedView
    }()
    
    private lazy var addressBar: UIView = {
        let view = UIStackView(arrangedSubviews: [
            addressTextField,
            reloadButton
        ])
        if viewModel.shouldShowWhitelistUIControls {
            view.insertArrangedSubview(toggleWhitelistDomainButton, at: 0)
            toggleWhitelistDomainButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            toggleWhitelistDomainButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        }
        
        reloadButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        reloadButton.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        
        addressTextField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        addressTextField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        view.axis = .horizontal
        view.spacing = stackViewSpacing
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let wrappedView = view.padding(all: 8)
        wrappedView.backgroundColor = IOSAsset.Colors.secondaryBackgroundColor.color
        wrappedView.heightAnchor.constraint(equalToConstant: addressBarHeight).isActive = true
        wrappedView.layer.cornerRadius = 8
        return wrappedView
    }()
    
    private lazy var addressTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = IOSStrings.Webviewcontroller.AddressTextfield.placeholder
        textField.borderStyle = .none
        textField.delegate = self
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.returnKeyType = .go
        textField.clearButtonMode = .whileEditing
        textField.textColor = IOSAsset.Colors.textColor.color
        textField.accessibilityLabel = IOSStrings.Webviewcontroller.AddressTextfield.accessibilityLabel
        textField.accessibilityHint = IOSStrings.Webviewcontroller.AddressTextfield.accessibilityHint
        return textField
    }()
    
    private lazy var reloadButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(
            IOSAsset.Assets.icReload24.image,
            for: .normal
        )
        button.tintColor = IOSAsset.Colors.textColor.color
        button.addTarget(self, action: #selector(reloadPage), for: .touchUpInside)
        button.accessibilityLabel = IOSStrings.Webviewcontroller.ReloadButton.accessibilityLabel
        button.accessibilityHint = IOSStrings.Webviewcontroller.ReloadButton.accessibilityHint
        button.accessibilityTraits = .button
        return button
    }()
    
    private lazy var toggleWhitelistDomainButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(
            IOSAsset.Assets.icProtectionEnabled.image,
            for: .normal
        )
        button.tintColor = IOSAsset.Colors.textColor.color
        button.addTarget(self, action: #selector(toggleWhitelistDomain), for: .touchUpInside)
        button.accessibilityLabel = IOSStrings.Webviewcontroller.ToggleWhitelistDomainButton.accessibilityLabel
        button.accessibilityHint = IOSStrings.Webviewcontroller.ToggleWhitelistDomainButton.accessibilityHint
        button.accessibilityTraits = .button
        return button
    }()
    
    private lazy var toolbar: UIView = {
        let view = UIStackView(arrangedSubviews: [
            UIView(),
            backButton,
            forwardButton
        ])
        if viewModel.shouldShowWhitelistUIControls {
            view.insertArrangedSubview(openWhitelistDomainsButton, at: 0)
        }
        view.axis = .horizontal
        view.spacing = 44
        view.heightAnchor.constraint(equalToConstant: toolbarHeight).isActive = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view.padding(horizontal: padding)
    }()
    
    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(
            IOSAsset.Assets.icToolbarBack.image,
            for: .normal
        )
        button.tintColor = IOSAsset.Colors.textColor.color
        button.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        button.accessibilityLabel = IOSStrings.Webviewcontroller.BackButton.accessibilityLabel
        button.accessibilityHint = IOSStrings.Webviewcontroller.BackButton.accessibilityHint
        button.accessibilityTraits = .button
        return button
    }()
    
    private lazy var forwardButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(
            IOSAsset.Assets.icToolbarForward.image,
            for: .normal
        )
        button.tintColor = IOSAsset.Colors.textColor.color
        button.addTarget(self, action: #selector(goForward), for: .touchUpInside)
        button.accessibilityLabel = IOSStrings.Webviewcontroller.ForwardButton.accessibilityLabel
        button.accessibilityHint = IOSStrings.Webviewcontroller.ForwardButton.accessibilityHint
        button.accessibilityTraits = .button
        return button
    }()
    
    private lazy var openWhitelistDomainsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(
            IOSAsset.Assets.icBookmarks.image,
            for: .normal
        )
        button.tintColor = IOSAsset.Colors.textColor.color
        button.addTarget(self, action: #selector(openWhitelistDomainsListView), for: .touchUpInside)
        button.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        button.accessibilityLabel = IOSStrings.Webviewcontroller.OpenWhitelistDomainsButton.accessibilityLabel
        button.accessibilityHint = IOSStrings.Webviewcontroller.OpenWhitelistDomainsButton.accessibilityHint
        button.accessibilityTraits = .button
        return button
    }()
    
    init(
        configuration: WKWebViewConfiguration,
        viewModel: WebViewModel
    ) {
        self.configuration = configuration
        self.viewModel = viewModel
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
        bindViewModel()
        setupKeyboardObservers()
        setupEstimatedProgressObserver()
        viewModel.loadDefaultPage()
    }
    
    private func setupUI() {
        view.backgroundColor = IOSAsset.Colors.primaryBackgroundColor.color
        view.addSubview(mainStackView)
        
        mainStackViewBottomConstraint = mainStackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        
        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mainStackViewBottomConstraint!
        ])
    }
    
    private func bindViewModel() {
        viewModel.$currentURL
            .sink { [weak self] url in
                self?.addressTextField.text = url?.absoluteString
            }
            .store(in: &cancellables)
        
        viewModel.$canGoBack
            .assign(to: \.isEnabled, on: backButton)
            .store(in: &cancellables)
        
        viewModel.$canGoForward
            .assign(to: \.isEnabled, on: forwardButton)
            .store(in: &cancellables)
        
        viewModel.$estimatedProgress
            .sink { [weak self] progress in
                self?.progressBar.progress = Float(progress)
                self?.progressBar.isHidden = progress == 1
            }
            .store(in: &cancellables)
        
        viewModel.callbacksPublisher
            .sink { [unowned webView] callback in
                switch callback {
                case .load(let url):
                    webView.load(URLRequest(url: url))
                case .goBack:
                    guard webView.canGoBack else { return }
                    webView.goBack()
                case .goForward:
                    guard webView.canGoForward else { return }
                    webView.goForward()
                }
            }
            .store(in: &cancellables)
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
        observer = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, change in
            DispatchQueue.main.async {
                self?.viewModel.estimatedProgress = webView.estimatedProgress
            }
        }
    }
    
    private func removeObservers() {
        NotificationCenter.default.removeObserver(self)
        observer?.invalidate()
        observer = nil
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard addressTextField.isFirstResponder else { return }
        
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
    
    // MARK: - Actions
    
    @objc private func goBack() {
        viewModel.goBack()
    }
    
    @objc private func goForward() {
        viewModel.goForward()
    }
    
    @objc private func reloadPage() {
        viewModel.reloadCurrentPage()
    }
    
    @objc private func toggleWhitelistDomain() {
        viewModel.toggleWhitelistDomain(for: webView.url?.host())
    }
    
    @objc private func openWhitelistDomainsListView() {
        viewModel.showWhiteListDomainsListView()
    }
}

extension WebViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if viewModel.tryToLoad(absoluteString: textField.text) {
            textField.resignFirstResponder()
        }
        return true
    }
}

extension WebViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !isKeyboardVisible else { return }
        guard scrollView.isDragging else { return }
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
