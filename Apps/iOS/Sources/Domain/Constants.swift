import UIKit

struct Constants {
    struct URL {
        static let DefaultSearchEngine = "https://www.duckduckgo.com"
    }
}

struct Dimensions {
    struct Size {
        static let DefaultButtonHeight: CGFloat = 44
        static let ToolbarHeight: CGFloat = 44.0
        static let AddressBarHeight: CGFloat = 40.0
    }
    
    struct Spacing {
        static let Default: CGFloat = 8
        static let Large: CGFloat = 8
    }
    
    struct Padding {
        static let Default: CGFloat = 8
    }
    
    struct Threashold {
        static let MinToHideBottomView: CGFloat = 100.0
    }
    
    struct Animation {
        static let KeyboardDuration: TimeInterval = 0.3
        static let ScrollDuration: TimeInterval = 0.3
    }
}
