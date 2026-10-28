import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    Self.prepareSecureStoreDirectory()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  /// The encrypted store lives in Application Support/brainstash. Its key is
  /// device-only (Keychain first_unlock_this_device), so a backup restored to
  /// another device could never be decrypted. Exclude it from backups instead.
  private static func prepareSecureStoreDirectory() {
    let fm = FileManager.default
    guard let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
    var dir = base.appendingPathComponent("brainstash", isDirectory: true)
    do {
      try fm.createDirectory(at: dir, withIntermediateDirectories: true,
                             attributes: [.protectionKey: FileProtectionType.complete])
      var values = URLResourceValues()
      values.isExcludedFromBackup = true
      try dir.setResourceValues(values)
    } catch {
      NSLog("Brainstash: could not prepare store directory: \(error.localizedDescription)")
    }
  }
}
