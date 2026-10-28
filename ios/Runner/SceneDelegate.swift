import Flutter
import UIKit

/// Adds a native privacy cover before iOS snapshots the app for the app
/// switcher (a Flutter-drawn cover may not render in time). Uses scene
/// notifications rather than overriding lifecycle methods, so Flutter's own
/// lifecycle forwarding is untouched.
class SceneDelegate: FlutterSceneDelegate {
  private var privacyCover: UIView?
  private var observers: [NSObjectProtocol] = []

  override init() {
    super.init()
    let nc = NotificationCenter.default
    observers.append(nc.addObserver(forName: UIScene.willDeactivateNotification, object: nil,
                                    queue: .main) { [weak self] _ in self?.showCover() })
    observers.append(nc.addObserver(forName: UIScene.didActivateNotification, object: nil,
                                    queue: .main) { [weak self] _ in self?.hideCover() })
  }

  deinit {
    observers.forEach(NotificationCenter.default.removeObserver)
  }

  private func showCover() {
    guard privacyCover == nil, let window = window else { return }
    let cover = UIView(frame: window.bounds)
    cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    cover.backgroundColor = UIColor(red: 15 / 255, green: 17 / 255, blue: 21 / 255, alpha: 1)
    window.addSubview(cover)
    privacyCover = cover
  }

  private func hideCover() {
    privacyCover?.removeFromSuperview()
    privacyCover = nil
  }
}
