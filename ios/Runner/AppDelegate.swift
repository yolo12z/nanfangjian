import UIKit
import Flutter
import CoreLocation

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let floatingChannel = FlutterMethodChannel(name: "com.example.custom_compass/floating",
                                              binaryMessenger: controller.binaryMessenger)

    // iOS 原生与 Flutter 的桥接配置
    floatingChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      switch call.method {
      case "checkOverlayPermission":
        // iOS 系统级悬浮窗受到苹果严格沙盒限制，画中画或系统仅支持内部浮窗
        result(false)
      case "requestOverlayPermission":
        result(false)
      case "showFloatingWindow":
        result(false)
      case "hideFloatingWindow":
        result(false)
      case "isFloating":
        result(false)
      default:
        result(FlutterMethodNotImplemented)
      }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
