import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Replace with your actual Google Maps API key
    // You can get one from: https://console.cloud.google.com/google/maps-apis/
    GMSServices.provideAPIKey("AIzaSyDExAMPLE_KEY_REPLACE_WITH_YOUR_ACTUAL_KEY")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}