import Flutter
import UIKit
import WatchConnectivity

private let kAppGroup = "group.app.auaha.proteingrid"
private let kTotal    = "pg_today_total"
private let kGoal     = "pg_daily_goal"
private let kStreak   = "pg_streak"
private let kPending  = "pg_pending_logs"

@main
@objc class AppDelegate: FlutterAppDelegate, WCSessionDelegate {

  private var watchChannel: FlutterMethodChannel?
  private var defaults: UserDefaults? { UserDefaults(suiteName: kAppGroup) }
  private var lastSyncArgs: [String: Any] = [:]

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if WCSession.isSupported() {
      WCSession.default.delegate = self
      WCSession.default.activate()
    }
    GeneratedPluginRegistrant.register(with: self)
    let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    if let controller = window?.rootViewController as? FlutterViewController {
      watchChannel = FlutterMethodChannel(
        name: "app.auaha.proteingrid/watch",
        binaryMessenger: controller.binaryMessenger
      )
      watchChannel?.setMethodCallHandler { [weak self] call, result in
        if call.method == "syncWatch", let args = call.arguments as? [String: Any] {
          self?.syncToWatch(args: args)
          result(nil)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
      drainPendingWatchLogs()
    }
    return result
  }

  // MARK: - Sync

  private let kUnlocked = "pg_watch_unlocked"

  private func syncToWatch(args: [String: Any]) {
    lastSyncArgs = args
    if let d = defaults {
      if let v = args[kTotal]  as? Double { d.set(v, forKey: kTotal) }
      if let v = args[kGoal]   as? Int    { d.set(Double(v), forKey: kGoal) }
      if let v = args[kStreak] as? Int    { d.set(v, forKey: kStreak) }
      d.set(args["watch_unlocked"] as? Bool ?? false, forKey: kUnlocked)
    }
    pushContextToWatch(args: args)
  }

  private func pushContextToWatch(args: [String: Any]) {
    guard WCSession.default.activationState == .activated else { return }
    let ctx: [String: Any] = [
      kTotal:  args[kTotal]  ?? 0.0,
      kGoal:   Double((args[kGoal]  as? Int) ?? 150),
      kStreak: args[kStreak] ?? 0,
      "watch_unlocked": args["watch_unlocked"] as? Bool ?? false,
    ]
    try? WCSession.default.updateApplicationContext(ctx)
  }

  // MARK: - Drain Watch pending logs

  private func drainPendingWatchLogs() {
    guard let d = defaults,
          let pending = d.array(forKey: kPending) as? [[String: Any]],
          !pending.isEmpty else { return }
    for entry in pending {
      if let grams = entry["grams"] as? Double {
        watchChannel?.invokeMethod("watchLog", arguments: grams)
      }
    }
    d.set([], forKey: kPending)
  }

  // MARK: - WCSessionDelegate

  func session(_ session: WCSession,
               activationDidCompleteWith state: WCSessionActivationState,
               error: Error?) {
    guard state == .activated, !lastSyncArgs.isEmpty else { return }
    DispatchQueue.main.async { self.pushContextToWatch(args: self.lastSyncArgs) }
  }

  func sessionDidBecomeInactive(_ session: WCSession) {}
  func sessionDidDeactivate(_ session: WCSession) {
    WCSession.default.activate()
  }

  func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
    guard message["action"] as? String == "log",
          let grams = message["grams"] as? Double else { return }
    DispatchQueue.main.async {
      self.watchChannel?.invokeMethod("watchLog", arguments: grams)
    }
  }

  func session(_ session: WCSession, didReceiveMessage message: [String: Any],
               replyHandler: @escaping ([String: Any]) -> Void) {
    guard message["action"] as? String == "requestState" else { return }
    let unlocked = lastSyncArgs["watch_unlocked"] as? Bool
      ?? defaults?.bool(forKey: kUnlocked)
      ?? false
    replyHandler([
      kTotal:  lastSyncArgs[kTotal]  ?? defaults?.double(forKey: kTotal)  ?? 0.0,
      kGoal:   lastSyncArgs[kGoal]   ?? defaults?.double(forKey: kGoal)   ?? 150.0,
      kStreak: lastSyncArgs[kStreak] ?? defaults?.integer(forKey: kStreak) ?? 0,
      "watch_unlocked": unlocked,
    ])
  }
}
