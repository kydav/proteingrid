import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    // After super, FlutterSceneDelegate has created the window + FlutterViewController.
    // Hand the messenger to AppDelegate so it can register the watch channel.
    if let vc = window?.rootViewController as? FlutterViewController,
       let appDelegate = UIApplication.shared.delegate as? AppDelegate {
      appDelegate.setupWatchChannel(with: vc)
    }
  }
}
