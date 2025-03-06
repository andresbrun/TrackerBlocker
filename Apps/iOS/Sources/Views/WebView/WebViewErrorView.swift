import UIKit

class WebViewErrorView: UIView {
    
    private lazy var stackView: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [imageView, titleLabel, descriptionLabel])
        stack.axis = .vertical
        stack.spacing = Dimensions.Spacing.Default
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = IOSAsset.Colors.textColor.color
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = IOSAsset.Colors.textColor.color
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Dimensions.Padding.Default),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Dimensions.Padding.Default),
        ])
        
        backgroundColor = IOSAsset.Colors.webViewBackgroundColor.color
    }
    
    func configure(model: WebViewError) {
        imageView.image = model.icon
        titleLabel.text = model.title
        descriptionLabel.text = model.message
    }
} 
