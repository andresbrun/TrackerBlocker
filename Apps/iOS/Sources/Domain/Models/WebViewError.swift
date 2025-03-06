import Foundation
import UIKit

struct WebViewError {
    let title: String
    let message: String
    let icon: UIImage
}

extension WebViewError {
    static var generic: WebViewError {
        .init(
            title: IOSStrings.Webviewcontroller.Error.Generic.title,
            message: IOSStrings.Webviewcontroller.Error.Generic.description,
            icon: IOSAsset.Assets.ilGenericError.image
        )
    }
}
