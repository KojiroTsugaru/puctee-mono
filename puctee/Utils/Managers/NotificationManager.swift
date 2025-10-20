//
//  NotificationManager.swift
//  puctee
//
//  Created by kj on 8/16/25.
//

import UserNotifications
import CoreLocation
import UIKit

// MARK: - Categories / Keys

enum NotificationCategory {
  static let planArrival = "PLAN_ARRIVAL_CHECK"
  static let planArrivalWakeUp = "PLAN_ARRIVAL_WAKEUP"
  static let planInvite  = "PLAN_INVITE"
  static let penaltyApprovalRequest = "PENALTY_APPROVAL_REQUEST"
  static let penaltyApprovedOrDeclined = "PENALTY_APPROVED_OR_DECLINED"
}

private enum NotificationPayloadKey {
  static let planId    = "plan_id"
  static let isArrived = "is_arrived"
  static let penaltyUserId = "penalty_user_id"
  static let requestId = "request_id"
}

// MARK: - Notification Manager

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
  static let shared = NotificationManager()
  private override init() {}
  
  // Public: call once on app launch
  @MainActor
  func configure() {
    let center = UNUserNotificationCenter.current()
    center.delegate = self
    center.setNotificationCategories(makeCategories())
    center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, err in
      if let err { print("‼️ Notification auth error:", err) }
      print("🔔 Notification permission:", granted)
    }
    UIApplication.shared.registerForRemoteNotifications()
  }
  
  @MainActor
  func registerForAPNs() {
    UIApplication.shared.registerForRemoteNotifications()
  }
  
  // MARK: UNUserNotificationCenterDelegate
  
  /// Notification tapped / action selected (app in background or terminated)
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
    let content = response.notification.request.content
    
    #if DEBUG
    logPayload(content, place: "didReceive")
    #endif
    
    switch content.categoryIdentifier {
      case NotificationCategory.planArrival:
        if let payload = extractArrivalPayload(from: content) {
          Task { @MainActor in
            DeepLinkHandler.shared.handleArrival(planId: payload.planId, isArrived: payload.isArrived)
          }
        }
        completionHandler()
      case NotificationCategory.penaltyApprovalRequest:
        if let payload = extractPenaltyApprovalPayload(from: content) {
          Task { @MainActor in
            DeepLinkHandler.shared.handlePenaltyApprovalRequest(requestId: payload)
          }
        }
        completionHandler()
      default:
        completionHandler()
    }
  }
  
  /// App is foreground when a notification arrives
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    let content = notification.request.content
    
    #if DEBUG
    logPayload(content, place: "willPresent")
    #endif
    
    switch content.categoryIdentifier {
      case NotificationCategory.planArrival:
        if let payload = extractArrivalPayload(from: content) {
          Task { @MainActor in
            DeepLinkHandler.shared.handleArrival(planId: payload.planId, isArrived: payload.isArrived)
          }
        }
        completionHandler([.banner, .sound, .badge])
      case NotificationCategory.penaltyApprovalRequest:
        if let payload = extractPenaltyApprovalPayload(from: content) {
          Task { @MainActor in
            DeepLinkHandler.shared.handlePenaltyApprovalRequest(requestId: payload)
          }
        }
        completionHandler([.banner, .sound, .badge])
      default:
        completionHandler([.banner, .sound, .badge])
    }
  }
  
  // MARK: AppDelegate
  
  /// AppDelegate call
  func didRegister(deviceToken: Data) {
    let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    Task { await updatePushToken(token) }
  }
  
  /// AppDelegate call
  func didFailToRegister(error: Error) {
    print("Failed to register for remote notifications: \(error)")
  }
  
  /// Update token
  private func updatePushToken(_ token: String) async {
    do {
      try await UserService.shared.updatePushToken(token: token)
    } catch {
      print("Failed to update token on the server: \(error)")
    }
  }
  
  // MARK: Public (Debug)
  
  /// サーバ経由のデバッグ用テストPush
  func testPushNotification() async throws {
    let url = URL(string: "\(Env.API.baseURL)users/me/test-push")!
    let params: [String: Any] = [
      "title": "Custom Title",
      "body":  "Custom Message"
    ]
    let body = try JSONSerialization.data(withJSONObject: params)
    _ = try await APIClient.shared.request(url: url, method: "POST", body: body)
  }
  
  // MARK: - Helpers
  
  /// Register all categories here
  private func makeCategories() -> Set<UNNotificationCategory> {
    let arrival = UNNotificationCategory(
      identifier: NotificationCategory.planArrival,
      actions: [],
      intentIdentifiers: [],
      options: [.customDismissAction]
    )
    
    let invite = UNNotificationCategory(
      identifier: NotificationCategory.planInvite,
      actions: [], // 例: 承認/拒否アクションを今後追加する余地
      intentIdentifiers: [],
      options: []
    )
    
    let penaltyApprovalRequest = UNNotificationCategory(
      identifier: NotificationCategory.penaltyApprovalRequest,
      actions: [],
      intentIdentifiers: [],
      options: [.customDismissAction]
    )
    
    return [arrival, invite, penaltyApprovalRequest]
  }
  
  /// 型安全＆ロバストに planArrival のペイロードを取り出す
  private func extractArrivalPayload(from content: UNNotificationContent) -> (planId: Int, isArrived: Bool?)? {
    let info = content.userInfo
    
    // plan_id は Int でも String でも来うる
    let planId: Int? = {
      if let n = info[NotificationPayloadKey.planId] as? Int { return n }
      if let s = info[NotificationPayloadKey.planId] as? String { return Int(s) }
      return nil
    }()
    
    // is_arrived は Bool 断定。String の "true"/"false" に来ることがある場合は拡張
    let isArrived: Bool? = {
      if let b = info[NotificationPayloadKey.isArrived] as? Bool { return b }
      if let s = info[NotificationPayloadKey.isArrived] as? String {
        return ["true", "1", "yes"].contains(s.lowercased())
      }
      return nil
    }()
    
    guard let pid = planId else { return nil }
    return (pid, isArrived)
  }
  
  /// 型安全に penaltyApprovalRequest のペイロードを取り出す
  private func extractPenaltyApprovalPayload(from content: UNNotificationContent)
  -> Int? {
    let info = content.userInfo
    
    let requestId: Int? = {
      if let n = info[NotificationPayloadKey.requestId] as? Int { return n }
      if let s = info[NotificationPayloadKey.requestId] as? String { return Int(s) }
      return nil
    }()
    
    guard let rid = requestId else { return nil }
    return rid
  }
  
  // NotificationManager.swift （末尾あたりに追加）
#if DEBUG
  private func prettyJSONString(_ dict: [AnyHashable: Any]) -> String {
    guard JSONSerialization.isValidJSONObject(dict) else {
      return String(describing: dict)
    }
    do {
      let data = try JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys])
      return String(data: data, encoding: .utf8) ?? String(describing: dict)
    } catch {
      return String(describing: dict)
    }
  }
  
  nonisolated private func logPayload(_ content: UNNotificationContent, place: String) {
    let info = content.userInfo
    print("🔔 [APNs payload @ \(place)] category=\(content.categoryIdentifier)")
    print(prettyJSONString(info))
  }
#endif
}

// MARK: Silent Notification
extension NotificationManager {
  /// AppDelegate から呼ばれる、サイレント(背景)通知の入口
  func handleSilentWake(userInfo: [AnyHashable: Any],
                        completion: @escaping (UIBackgroundFetchResult) -> Void) {
    // 1) これは「到着チェック起床」か？
    guard isWakeUpPush(userInfo) else {
      completion(.noData)
      return
    }
    // 2) plan_id 抽出
    guard let planId = extractPlanId(userInfo) else {
      print("⚠️ WakeUp push but missing plan_id")
      completion(.noData)
      return
    }
    
    // 3) 現在地取得 → PlanService.checkArrival を実行（UIは出さない）
    Task {
      do {
        guard let coord = await currentCoordinateForWake() else {
          print("⚠️ No coordinate available for wake-up plan \(planId)")
          completion(.noData)
          return
        }
        let req = LocationCheckRequest(
          latitude:  Double(coord.latitude),
          longitude: Double(coord.longitude)
        )
        let _ = try await PlanService.shared.checkArrival(planId: planId, locationCheckReqest: req)
        // 結果の可視化はサーバが返す APNs（PLAN_ARRIVAL_CHECK）に任せる
        completion(.newData)
      } catch {
        completion(.failed)
      }
    }
  }
  
  // MARK: - Helpers (silent wake)
  
  /// WakeUp 用カテゴリかどうか判定（aps.category or userInfo["category"/"type"]）
  private func isWakeUpPush(_ userInfo: [AnyHashable: Any]) -> Bool {
    guard let aps = userInfo["aps"] as? [String: Any] else { return false }
    let category = (aps["category"] as? String) ?? (userInfo["category"] as? String)
    // ① カテゴリが PLAN_ARRIVAL_WAKEUP のみ許可（フォールバック廃止）
    guard category == NotificationCategory.planArrivalWakeUp else { return false }
    // ② 完全サイレント（alert が無い）だけを起床扱い
    if aps["alert"] != nil { return false }
    // ③ content-available:1 を明示チェック（無くても良いが入ってる想定）
    if let ca = aps["content-available"] as? Int, ca != 1 { return false }
    return true
  }
  
  /// plan_id を Int で取り出す
  private func extractPlanId(_ userInfo: [AnyHashable: Any]) -> Int? {
    if let n = userInfo[NotificationPayloadKey.planId] as? Int { return n }
    if let s = userInfo[NotificationPayloadKey.planId] as? String { return Int(s) }
    // aps.alert.userInfo に含む場合の保険
    if let aps = userInfo["aps"] as? [String: Any],
       let dict = aps["userInfo"] as? [String: Any] {
      if let n = dict[NotificationPayloadKey.planId] as? Int { return n }
      if let s = dict[NotificationPayloadKey.planId] as? String { return Int(s) }
    }
    return nil
  }
  
  /// 背景でも成功しやすい現在地トライ（短めタイムアウト＋キャッシュ）
  private func currentCoordinateForWake() async -> CLLocationCoordinate2D? {
    if let c = try? await LocationManager.shared.getUserCoordinate(timeout: 8) {
      return c
    }
    if let c = LocationManager.shared.userCoordinate { // キャッシュ
      return c
    }
#if DEBUG
#if targetEnvironment(simulator)
    // シミュレータの保険（Apple Park）
    return .init(latitude: 37.3349, longitude: -122.0090)
#endif
#endif
    return nil
  }
}

// for checking device status
extension NotificationManager {
  func debug_dumpSilentEnvironment() {
    let bg = UIApplication.shared.backgroundRefreshStatus
    print("🧪 BackgroundRefreshStatus:", bg == .available ? "available" :
            bg == .denied ? "denied" : "restricted")
    if let arr = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] {
      print("🧪 UIBackgroundModes:", arr)
    }
  }
}

extension NotificationManager {
  /// アプリが foreground になった時に、通知センターに残っている通知を回収して
  /// ModalCoordinator のキューに流し込み、重複防止のため通知を消す。
  func recoverDeliveredPushes() {
    let center = UNUserNotificationCenter.current()
    center.getDeliveredNotifications { [weak self] notes in
      guard let self else { return }
      
      // 対象カテゴリだけ抽出し、古い順（date昇順）にする
      let targets = notes
        .filter { note in
          let cat = note.request.content.categoryIdentifier
          return cat == NotificationCategory.planArrival
          || cat == NotificationCategory.penaltyApprovalRequest
        }
        .sorted(by: { $0.date < $1.date })
      
      var consumedIDs: [String] = []
      
      for note in targets {
        let content = note.request.content
        let cat = content.categoryIdentifier
        
        switch cat {
          case NotificationCategory.planArrival:
            if let p = self.extractArrivalPayload(from: content) {
              DispatchQueue.main.async {
                ModalCoordinator.shared.enqueue(.arrival(planId: p.planId, isArrived: p.isArrived))
              }
              consumedIDs.append(note.request.identifier)
            }
            
          case NotificationCategory.penaltyApprovalRequest:
            if let requestId = self.extractPenaltyApprovalPayload(from: content) {
              DispatchQueue.main.async {
                ModalCoordinator.shared.enqueue(.penaltyApprovalRequest(requestId: requestId))
              }
              consumedIDs.append(note.request.identifier)
            }
            
          default:
            break
        }
      }
      
      // キュー投入済みの通知を通知センターから除去（重複防止）
      if !consumedIDs.isEmpty {
        center.removeDeliveredNotifications(withIdentifiers: consumedIDs)
      }
    }
  }
}

