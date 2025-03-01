import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)

        let webViewController = WebViewController(nibName: nil, bundle: nil)
        let navigationController = UINavigationController(rootViewController: webViewController)

        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()

        return true
    }
}
