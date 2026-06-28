import Combine
import WatchConnectivity
import SwiftUI

private let kAppGroup  = "group.app.auaha.proteingrid"
private let kTotal     = "pg_today_total"
private let kGoal      = "pg_daily_goal"
private let kStreak    = "pg_streak"
private let kPending   = "pg_pending_logs"
private let kUnlocked  = "pg_watch_unlocked"

class ProteinStore: NSObject, ObservableObject {
    @Published var todayTotal: Double = 0
    @Published var dailyGoal: Double  = 150
    @Published var streak: Int        = 0
    @Published var isUnlocked: Bool   = false

    private var defaults: UserDefaults? { UserDefaults(suiteName: kAppGroup) }

    override init() {
        super.init()
        loadFromDefaults()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    // MARK: - Logging

    func log(grams: Double) {
        todayTotal += grams
        defaults?.set(todayTotal, forKey: kTotal)
        sendToPhone(grams: grams)
    }

    private func sendToPhone(grams: Double) {
        let msg: [String: Any] = [
            "action": "log",
            "grams": grams,
            "timestamp": Date().timeIntervalSince1970,
        ]
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(msg, replyHandler: nil)
        } else {
            var pending = defaults?.array(forKey: kPending) as? [[String: Any]] ?? []
            pending.append(msg)
            defaults?.set(pending, forKey: kPending)
        }
    }

    // MARK: - Persistence

    private func loadFromDefaults() {
        guard let d = defaults else { return }
        todayTotal = d.double(forKey: kTotal)
        let goal   = d.double(forKey: kGoal)
        dailyGoal  = goal > 0 ? goal : 150
        streak     = d.integer(forKey: kStreak)
        isUnlocked = d.bool(forKey: kUnlocked)
    }

    private func applyContext(_ ctx: [String: Any]) {
        if let v = ctx[kTotal]  as? Double { todayTotal = v; defaults?.set(v, forKey: kTotal) }
        if let v = ctx[kGoal]   as? Double { dailyGoal  = v; defaults?.set(v, forKey: kGoal)  }
        if let v = ctx[kStreak] as? Int    { streak     = v; defaults?.set(v, forKey: kStreak) }
        if let v = ctx["watch_unlocked"] as? Bool {
            isUnlocked = v
            defaults?.set(v, forKey: kUnlocked)
        }
    }
}

// MARK: - WCSessionDelegate

extension ProteinStore: WCSessionDelegate {
    func session(_ session: WCSession,
                 activationDidCompleteWith state: WCSessionActivationState,
                 error: Error?) {
        DispatchQueue.main.async {
            self.loadFromDefaults()
            let cached = session.receivedApplicationContext
            if !cached.isEmpty { self.applyContext(cached) }
        }
        guard state == .activated else { return }
        if session.isReachable {
            session.sendMessage(["action": "requestState"], replyHandler: { [weak self] reply in
                DispatchQueue.main.async { self?.applyContext(reply) }
            }, errorHandler: nil)
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async { self.applyContext(message) }
    }

    func session(_ session: WCSession,
                 didReceiveApplicationContext ctx: [String: Any]) {
        DispatchQueue.main.async { self.applyContext(ctx) }
    }
}
