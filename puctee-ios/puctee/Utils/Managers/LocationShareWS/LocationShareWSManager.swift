//
//  LocationShareWSManager.swift
//  puctee
//
//  Created by kj on 9/7/25.
//

import Supabase
import Realtime
import Combine
import Observation
import CoreLocation
import Foundation

@Observable class LocationShareWSManager {
  private let websocketClient = WebsocketClient.shared
  private let decoder = SnakeCaseJSONDecoder()
  private var realtimeChannel: RealtimeChannelV2?
  private var locationUpdateTimer: Timer?
  private let locationManager = LocationManager.shared
  
  var locations: [Int: LocationShare] = [:] // user_id -> LocationShare
  var errorMessage: String?
  var isSharing = false
  
  private let planId: Int
  private let userId: Int
  private let userDisplayName: String
  private let userProfileImageUrl: String?
  
  init(planId: Int, userId: Int, userDisplayName: String, userProfileImageUrl: String? = nil) {
    self.planId = planId
    self.userId = userId
    self.userDisplayName = userDisplayName
    self.userProfileImageUrl = userProfileImageUrl
  }
  
  // リアルタイム位置情報共有を開始
  func startLocationSharing() async {
    print("🚀 [LocationShare] Starting location sharing for plan \(planId), user \(userId)")
    
    // まず参加者検証
    /*
    do {
      let isValid = try await PlanService.shared.validateAccess(planId: planId, userId: userId)
      guard isValid else {
        print("❌ [LocationShare] Access denied for plan \(planId), user \(userId)")
        await MainActor.run {
          self.errorMessage = "Access denied: Not a participant of this plan"
        }
        return
      }
      print("✅ [LocationShare] Access validated for plan \(planId)")
    } catch {
      print("❌ [LocationShare] Validation error: \(error)")
      self.errorMessage = "Error validating access: \(error)"
      return
    }
     */
    
    // Supabase Realtimeチャンネルに接続
    print("🔌 [LocationShare] Connecting to channel: plan_location_\(planId)")
    realtimeChannel = await websocketClient.getChannel(channelId: "plan_location_\(planId)")

    // 位置情報の変更を監視
    let changeStream = await realtimeChannel?.postgresChange(
      AnyAction.self,
      schema: "public",
      table: "location_shares",
      filter: "plan_id=eq.\(planId)"
    )
    
    // Start listening to changes in a background task
    Task {
      guard let stream = changeStream else { 
        print("❌ [LocationShare] No change stream available")
        return 
      }
      print("👂 [LocationShare] Listening for location changes...")
      for await change in stream {
        print("📍 [LocationShare] Received location update: \(change)")
        await MainActor.run {
          self.handleLocationUpdate(change)
        }
      }
    }
    
    // チャンネル接続
    print("🔗 [LocationShare] Subscribing to channel...")
    await realtimeChannel?.subscribe()
    
    // 既存の位置情報を取得
    print("📥 [LocationShare] Loading existing locations...")
    await loadExistingLocations()
    
    // 位置情報権限をリクエスト
    print("🔐 [LocationShare] Requesting location authorization...")
    locationManager.requestAuthorization()
    
    // 位置情報共有を開始
    await MainActor.run {
      self.isSharing = true
    }
    print("✅ [LocationShare] Location sharing enabled")
    
    // 定期的な位置情報更新を開始
    print("⏰ [LocationShare] Starting periodic location updates...")
    startPeriodicLocationUpdates()
  }
  
  // 位置情報を送信
  func sendLocationUpdate(latitude: Double, longitude: Double) async {
    print("📤 [LocationShare] Sending location update: lat=\(latitude), lng=\(longitude)")
    
    let locationData = LocationShare(
      id: nil,
      planId: planId,
      userId: userId,
      displayName: userDisplayName,
      profileImageUrl: userProfileImageUrl,
      latitude: latitude,
      longitude: longitude,
      createdAt: nil,
      updatedAt: nil
    )
    
    do {
      try await websocketClient.database
        .from("location_shares")
        .upsert(locationData, onConflict: "plan_id,user_id")
        .execute()
      print("✅ [LocationShare] Location sent successfully")
    } catch {
      print("❌ [LocationShare] Failed to send location: \(error)")
      await MainActor.run {
        self.errorMessage = "Failed to send location: \(error.localizedDescription)"
      }
    }
  }
  
  // 既存の位置情報を読み込み
  private func loadExistingLocations() async {
    do {
      let response: [LocationShare] = try await websocketClient.database
        .from("location_shares")
        .select()
        .eq("plan_id", value: planId)
        .execute()
        .value
      
      await MainActor.run {
        for location in response {
          self.locations[location.userId] = location
        }
      }
    } catch {
      await MainActor.run {
        self.errorMessage = "Failed to load existing locations: \(error.localizedDescription)"
      }
    }
  }
  
  // リアルタイム更新を処理
  private func handleLocationUpdate(_ change: AnyAction) {
    switch change {
    case .insert(let insertAction):
      if let location = try? insertAction.decodeRecord(as: LocationShare.self, decoder: decoder) {
        locations[location.userId] = location
      }
    case .update(let updateAction):
      if let location = try? updateAction.decodeRecord(as: LocationShare.self, decoder: decoder) {
        locations[location.userId] = location
      }
    case .delete(let deleteAction):
      if let location = try? deleteAction.decodeOldRecord(as: LocationShare.self, decoder: decoder) {
        locations.removeValue(forKey: location.userId)
      }
    case .select(_):
      break
    }
  }
  
  // 接続を終了
  func disconnect() async {
    await realtimeChannel?.unsubscribe()
    realtimeChannel = nil
    
    // 定期更新を停止
    locationUpdateTimer?.invalidate()
    locationUpdateTimer = nil
    
    await MainActor.run {
      self.isSharing = false
      self.locations.removeAll()
    }
  }
  
  // 定期的な位置情報更新を開始
  private func startPeriodicLocationUpdates() {
    locationUpdateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
      Task {
        await self?.sendCurrentLocation()
      }
    }
    
    // 初回の位置情報送信
    Task {
      await sendCurrentLocation()
    }
  }
  
  // 現在の位置情報を取得して送信
  private func sendCurrentLocation() async {
    guard isSharing else { 
      print("⏸️ [LocationShare] Not sharing, skipping location update")
      return 
    }
    
    print("📍 [LocationShare] Getting current location...")
    do {
      let coordinate = try await locationManager.getUserCoordinate()
      print("✅ [LocationShare] Got location: \(coordinate.latitude), \(coordinate.longitude)")
      await sendLocationUpdate(latitude: coordinate.latitude, longitude: coordinate.longitude)
    } catch {
      print("❌ [LocationShare] Failed to get location: \(error)")
      await MainActor.run {
        self.errorMessage = "Failed to get location: \(error.localizedDescription)"
      }
    }
  }
}
