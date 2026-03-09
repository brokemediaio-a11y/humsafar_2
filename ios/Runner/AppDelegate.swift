import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Google Maps with API key from Info.plist
    // Alternative: You can also hardcode it here: GMSServices.provideAPIKey("YOUR_API_KEY")
    if let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
       let plist = NSDictionary(contentsOfFile: path),
       let apiKey = plist["GMSApiKey"] as? String {
      GMSServices.provideAPIKey(apiKey)
    } else {
      // Fallback: Use hardcoded key if Info.plist reading fails
      GMSServices.provideAPIKey("AIzaSyAh4gGqp-Ex2jV5Io5NfkUAg-1UZC8NvYk")
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
