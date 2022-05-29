import UIKit
import Flutter
import GoogleMaps
import Firebase

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyAAhV3gzsXMRUU-J7Je_P1vk4ld4rCJ_j2s")
    GeneratedPluginRegistrant.register(with: self)
    
    if FirebaseApp.app() == nil {
        FirebaseApp.configure()
    }
    FirebaseOptions.defaultOptions()?.deepLinkURLScheme = "https://flutterapplink.page.link"
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
//    override func application(_ application: UIApplication, continue userActivity: NSUserActivity,
//                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
//      let handled = DynamicLinks.dynamicLinks().handleUniversalLink(userActivity.webpageURL!) { (dynamiclink, error) in
//        // ...
//      }
//
//        return false}
//    
//    @available(iOS 9.0, *)
//    override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
//      return application(app, open: url,
//                         sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
//                         annotation: "")
//    }
    
}
