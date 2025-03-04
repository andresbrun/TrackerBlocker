import UIKit
import Foundation

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    private lazy var appCompositionRoot: AppCompositionRoot = {
        AppCompositionRoot()
    }()
    private lazy var rootNavigator: RootNavigator = {
        AppRootNavigator(appCompositionRoot: appCompositionRoot)
    }()
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        
        rootNavigator.initializeNavigation(in: window!)
        
        window!.makeKeyAndVisible()
        
        return true
    }
}
