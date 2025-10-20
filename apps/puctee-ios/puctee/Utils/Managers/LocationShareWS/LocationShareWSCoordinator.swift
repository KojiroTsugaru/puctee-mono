//
//  LocationWebSocketCoordinator.swift
//  puctee
//
//  Created by kj on 8/25/25.
//

import Foundation
import Observation

@Observable
final class LocationShareWSCoordinator {
  // 公開：監視用に見たいときだけ
  private(set) var managers: [Int: LocationShareWSManager] = [:]
  
  // 内部状態
  private var latestPlans: [Int: Plan] = [:]
  private var stopTimers: [Int: Timer] = [:]
  private var tickTimer: Timer?
  
  private let lead: TimeInterval
  private let accountManager: AccountManager
  
  init(accountManager: AccountManager, lead: TimeInterval = 15 * 60) {
    self.accountManager = accountManager
    self.lead = lead
    // 毎分「接続対象を再計算」
    tickTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
      self?.reconcile()
    }
  }
  
  deinit {
    tickTimer?.invalidate()
    for t in stopTimers.values { t.invalidate() }
    stopTimers.removeAll()
    for m in managers.values { Task { await m.disconnect() } }
    managers.removeAll()
  }
  
  /// Plan の最新スナップショットを渡して再計算
  func updatePlans(_ plans: [Plan]) {
    latestPlans = Dictionary(uniqueKeysWithValues: plans.map { ($0.id, $0) })
    reconcile()
  }
  
  /// 明示的に切断したい時用（例：plan 削除時など）
  func disconnect(planId: Int, reason: String = "manual") {
    if let m = managers.removeValue(forKey: planId) {
      Task { await m.disconnect() }
      print("Stopped WebSocket for plan \(planId) (\(reason))")
    }
    if let t = stopTimers.removeValue(forKey: planId) {
      t.invalidate()
    }
  }
  
  func getWebsocket(planId: Int) -> LocationShareWSManager? {
    guard managers.contains(where: { $0.key == planId }) else { return nil }
    return managers[planId]
  }
  
  // MARK: - Core
  
  /// 最新の plans をもとに「つなぐ／切る」を整合
  private func reconcile() {
    let now = Date()
    let plans = Array(latestPlans.values)
    
    // 今つなぐべき plan の集合
    let shouldConnectIDs = Set(
      plans.filter { shouldConnect($0, now: now) }.map { $0.id }
    )
    
    // つなぐ（新規のみ）
    for plan in plans where shouldConnectIDs.contains(plan.id) {
      guard let currentUser = accountManager.currentUser else { continue }
      connectIfNeeded(for: plan, user: currentUser)
      scheduleStopTimer(for: plan) // startTime 到達で即切断
    }
    
    // 不要なものは即切断
    for (pid, _) in managers where !shouldConnectIDs.contains(pid) {
      disconnect(planId: pid, reason: "out of window / status change")
    }
  }
  
  private func shouldConnect(_ plan: Plan, now: Date) -> Bool {
    let interval = plan.startTime.timeIntervalSince(now)
    return (interval > 0 && interval <= lead)
    && plan.participants.count > 1
    && plan.status == .upcoming
  }
  
  
  
  private func connectIfNeeded(for plan: Plan, user: User) {
    guard managers[plan.id] == nil else { return }
    
    let manager = LocationShareWSManager(
      planId: plan.id,
      userId: user.id,
      userDisplayName: user.displayName,
      userProfileImageUrl: user.profileImageUrl?.absoluteString)
    managers[plan.id] = manager
    
    // 位置情報共有を開始
    Task {
      await manager.startLocationSharing()
    }
  }
  
  private func scheduleStopTimer(for plan: Plan) {
    // 既存は更新
    stopTimers[plan.id]?.invalidate()
    
    let fireDate = plan.startTime
    guard fireDate > Date() else {
      // もう開始時刻を過ぎていれば即切断
      disconnect(planId: plan.id, reason: "startTime passed")
      return
    }
    
    let timer = Timer(fire: fireDate, interval: 0, repeats: false) { [weak self] _ in
      self?.disconnect(planId: plan.id, reason: "startTime reached")
    }
    RunLoop.main.add(timer, forMode: .common)
    stopTimers[plan.id] = timer
  }
}
