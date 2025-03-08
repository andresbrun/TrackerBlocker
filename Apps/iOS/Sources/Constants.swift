import UIKit

struct Constants {
    struct URL {
        static let DefaultSearchEngine = "https://www.duckduckgo.com"
        static let TDS = "https://staticcdn.duckduckgo.com/trackerblocking/v2.1/tds.json"
    }
    
    struct Key {
        static let Identifier = "LastRuleListIdentifier"
        static let Etag = "ETag"
    }
}

struct Dimensions {
    struct Size {
        static let DefaultButtonHeight: CGFloat = 44
        static let ToolbarHeight: CGFloat = 44.0
        static let AddressBarHeight: CGFloat = 40.0
        static let ToggleWidth: CGFloat = 60
    }
    
    struct Spacing {
        static let Default: CGFloat = 8
        static let Large: CGFloat = 32
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
