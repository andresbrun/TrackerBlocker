import UIKit
import Foundation

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

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
        appCompositionRoot.initializeRulesManagerIfNeeded()
        
        window!.makeKeyAndVisible()
        
        return true
    }
}
