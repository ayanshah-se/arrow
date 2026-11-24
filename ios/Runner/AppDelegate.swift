import Flutter
import UIKit
import AudioToolbox

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let launched = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "arrows/haptics",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { call, result in
        guard call.method == "vibrate" else {
          result(FlutterMethodNotImplemented)
          return
        }
        let args = call.arguments as? [String: Any]
        let strong = args?["strong"] as? Bool ?? true
        if strong {
          let gen = UINotificationFeedbackGenerator()
          gen.prepare()
          gen.notificationOccurred(.error)
          AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
        } else {
          let gen = UIImpactFeedbackGenerator(style: .medium)
          gen.prepare()
          gen.impactOccurred()
        }
        result(true)
      }
    }

    return launched
  }
}
