import UIKit

extension UIView {
    /// Wraps the view inside a container view with specified padding for each side
    /// - Parameters:
    ///   - top: Top padding
    ///   - left: Left padding
    ///   - bottom: Bottom padding
    ///   - right: Right padding
    /// - Returns: A new container view with this view inside it
    func padding(top: CGFloat = 0, left: CGFloat = 0, bottom: CGFloat = 0, right: CGFloat = 0) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        self.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(self)
        
        NSLayoutConstraint.activate([
            self.topAnchor.constraint(equalTo: containerView.topAnchor, constant: top),
            self.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: left),
            self.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -right),
            self.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -bottom)
        ])
        
        return containerView
    }
} 