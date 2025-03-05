import UIKit

extension UIView {
    /// Wraps the view inside a container view with specified padding for each side
    /// - Parameters:
    ///   - horizontal: Top and Bottom padding
    ///   - vertical: Left and Right padding
    /// - Returns: A new container view with this view inside it
    func padding(
        horizontal: CGFloat = 0,
        vertical: CGFloat = 0
    ) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(self)
        
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: containerView.topAnchor, constant: vertical),
            leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: horizontal),
            trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -horizontal),
            bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -vertical)
        ])
        
        return containerView
    }
    
    func padding(
        all: CGFloat = 0
    ) -> UIView {
        padding(
            horizontal: all,
            vertical: all
        )
    }
}
