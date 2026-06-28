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

  private let kUnlocked       = "pg_watch_unlocked"
  private let kCachedUnlocked = "pg_cached_watch_unlocked"  // survives restarts

  private func boolFromArgs(_ args: [String: Any], key: String) -> Bool {
    if let b = args[key] as? Bool    { return b }
    if let n = args[key] as? NSNumber { return n.boolValue }
    return false
  }

  private func syncToWatch(args: [String: Any]) {
    lastSyncArgs = args
    let unlocked = boolFromArgs(args, key: "watch_unlocked")
    UserDefaults.standard.set(unlocked, forKey: kCachedUnlocked)
    if let d = defaults {
      if let v = args[kTotal]  as? Double { d.set(v, forKey: kTotal) }
      if let v = args[kGoal]   as? Int    { d.set(Double(v), forKey: kGoal) }
      if let v = args[kStreak] as? Int    { d.set(v, forKey: kStreak) }
      d.set(unlocked, forKey: kUnlocked)
      // Debug trace — remove after diagnosis
      d.set("wu=\(unlocked) raw=\(String(describing: args["watch_unlocked"]))", forKey: "pg_ios_trace")
    }
    pushContextToWatch(args: args)
  }

  private func pushContextToWatch(args: [String: Any]) {
    guard WCSession.default.activationState == .activated else { return }
    let unlocked = boolFromArgs(args, key: "watch_unlocked")
    let ctx: [String: Any] = [
      kTotal:  args[kTotal]  ?? 0.0,
      kGoal:   Double((args[kGoal]  as? Int) ?? 150),
      kStreak: args[kStreak] ?? 0,
      "watch_unlocked": unlocked,
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
    guard state == .activated else { return }
    if !lastSyncArgs.isEmpty {
      DispatchQueue.main.async { self.pushContextToWatch(args: self.lastSyncArgs) }
    } else if UserDefaults.standard.bool(forKey: kCachedUnlocked) {
      // Flutter hasn't started yet but we know the user is subscribed — push immediately
      DispatchQueue.main.async {
        try? WCSession.default.updateApplicationContext(["watch_unlocked": true])
      }
    }
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
    let unlocked = (lastSyncArgs["watch_unlocked"] as? Bool)
      ?? defaults?.bool(forKey: kUnlocked)
      ?? UserDefaults.standard.bool(forKey: kCachedUnlocked)
    replyHandler([
      kTotal:  lastSyncArgs[kTotal]  ?? defaults?.double(forKey: kTotal)  ?? 0.0,
      kGoal:   lastSyncArgs[kGoal]   ?? defaults?.double(forKey: kGoal)   ?? 150.0,
      kStreak: lastSyncArgs[kStreak] ?? defaults?.integer(forKey: kStreak) ?? 0,
      "watch_unlocked": unlocked,
    ])
  }
}
