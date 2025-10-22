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
  private var isSendingLocation = false
  private var pendingLocationUpdate: (latitude: Double, longitude: Double)?
  private var lastSentLocation: CLLocationCoordinate2D?
  private var lastSentTime: Date?
  private let minimumUpdateInterval: TimeInterval = 10.0  // Minimum 10 seconds interval (iOS 18.4 compatible)
  private let minimumDistanceChange: CLLocationDistance = 20.0  // Minimum 20m movement (iOS 18.4 compatible)
  
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
  
  // Start real-time location sharing
  func startLocationSharing() async {
    print("🚀 [LocationShare] Starting location sharing for plan \(planId), user \(userId)")
    
    // Connect to Supabase Realtime channel
    print("🔌 [LocationShare] Connecting to channel: plan_location_\(planId)")
    realtimeChannel = await websocketClient.getChannel(channelId: "plan_location_\(planId)")

    // Monitor location changes
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
    
    // Subscribe to channel
    print("🔗 [LocationShare] Subscribing to channel...")
    await realtimeChannel?.subscribe()
    
    // Load existing locations
    // TODO: Enable after RLS policy setup
    // print("📥 [LocationShare] Loading existing locations...")
    // await loadExistingLocations()
    print("⏭️ [LocationShare] Skipping existing locations load (relying on realtime updates)")
    
    // Request location authorization
    print("🔐 [LocationShare] Requesting location authorization...")
    locationManager.requestAuthorization()
    
    // Start location sharing
    await MainActor.run {
      self.isSharing = true
    }
    print("✅ [LocationShare] Location sharing enabled")
    
    // Start periodic location updates
    print("⏰ [LocationShare] Starting periodic location updates...")
    startPeriodicLocationUpdates()
  }
  
  // Send location update
  func sendLocationUpdate(latitude: Double, longitude: Double) async {
    let newLocation = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    
    // Throttling: Check both time and distance
    if let lastTime = lastSentTime, let lastLoc = lastSentLocation {
      let timeSinceLastSend = Date().timeIntervalSince(lastTime)
      let distance = calculateDistance(from: lastLoc, to: newLocation)
      
      // Skip if both time and distance are below threshold
      if timeSinceLastSend < minimumUpdateInterval && distance < minimumDistanceChange {
        print("⏭️ [LocationShare] Skipping update (time: \(String(format: "%.1f", timeSinceLastSend))s, distance: \(String(format: "%.1f", distance))m)")
        return
      }
    }
    
    // If already sending, queue the latest location for later
    guard !isSendingLocation else {
      print("⏳ [LocationShare] Already sending, queuing update: lat=\(latitude), lng=\(longitude)")
      pendingLocationUpdate = (latitude, longitude)
      return
    }
    
    isSendingLocation = true
    defer { isSendingLocation = false }
    
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
    
    // Retry logic: Max 5 attempts with longer wait times (iOS 18.4 compatible)
    var lastError: Error?
    for attempt in 1...5 {
      do {
        try await websocketClient.database
          .from("location_shares")
          .upsert(locationData, onConflict: "plan_id,user_id")
          .execute()
        print("✅ [LocationShare] Location sent successfully (attempt \(attempt))")
        
        // Record on successful send
        lastSentLocation = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        lastSentTime = Date()
        
        // If successful, send pending update if any
        if let pending = pendingLocationUpdate {
          pendingLocationUpdate = nil
          Task {
            await sendLocationUpdate(latitude: pending.latitude, longitude: pending.longitude)
          }
        }
        return
      } catch let error as NSError {
        lastError = error
        
        // Simplify logs for iOS 18.4 network errors (-1005)
        if error.domain == NSURLErrorDomain && error.code == -1005 {
          if attempt == 5 {
            print("❌ [LocationShare] Network unstable (iOS 18.4), gave up after 5 attempts")
          }
        } else {
          print("⚠️ [LocationShare] Failed (attempt \(attempt)/5): \(error.localizedDescription)")
        }
        
        // Wait longer if not the last attempt (iOS 18.4 compatible)
        if attempt < 5 {
          let backoffSeconds = Double(attempt) * 1.5  // 1.5s, 3s, 4.5s, 6s
          let nanoseconds = UInt64(backoffSeconds * 1_000_000_000)
          try? await Task.sleep(nanoseconds: nanoseconds)
        }
      } catch {
        lastError = error
        print("⚠️ [LocationShare] Unexpected error (attempt \(attempt)/5): \(error)")
        
        if attempt < 5 {
          let backoffSeconds = Double(attempt) * 1.5
          try? await Task.sleep(nanoseconds: UInt64(backoffSeconds * 1_000_000_000))
        }
      }
    }
    
    // If all 5 attempts failed (no error message - will auto-retry next time)
    if let error = lastError {
      print("❌ [LocationShare] Failed after 5 attempts, will retry on next update")
    }
  }
  
  // Load existing locations (excluding self)
  private func loadExistingLocations() async {
    print("🔍 [LocationShare] Fetching locations for plan \(planId), excluding user \(userId)")
    
    // Request with timeout
    do {
      let response: [LocationShare] = try await withTimeout(seconds: 10) {
        try await self.websocketClient.database
          .from("location_shares")
          .select()
          .eq("plan_id", value: self.planId)
          .neq("user_id", value: self.userId)  // Exclude own location
          .execute()
          .value
      }
      
      print("✅ [LocationShare] Received \(response.count) locations from database")
      
      await MainActor.run {
        for location in response {
          print("📌 [LocationShare] Adding location for user \(location.userId): \(location.displayName)")
          self.locations[location.userId] = location
        }
      }
      print("📍 [LocationShare] Loaded \(response.count) other users' locations")
    } catch is TimeoutError {
      print("⏱️ [LocationShare] Request timed out after 10 seconds")
      await MainActor.run {
        self.errorMessage = "Failed to load locations: Request timed out"
      }
    } catch {
      print("❌ [LocationShare] Failed to load existing locations: \(error)")
      print("❌ [LocationShare] Error details: \(String(describing: error))")
      await MainActor.run {
        self.errorMessage = "Failed to load existing locations: \(error.localizedDescription)"
      }
    }
  }
  
  // Timeout helper
  private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
      group.addTask {
        try await operation()
      }
      
      group.addTask {
        try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
        throw TimeoutError()
      }
      
      let result = try await group.next()!
      group.cancelAll()
      return result
    }
  }
  
  struct TimeoutError: Error {}
  
  // Handle realtime updates (excluding self)
  private func handleLocationUpdate(_ change: AnyAction) {
    switch change {
    case .insert(let insertAction):
      if let location = parseLocationFromRecord(insertAction.record) {
        // Ignore own location
        guard location.userId != userId else {
          print("🚫 [LocationShare] Ignoring own location insert")
          return
        }
        print("➕ [LocationShare] Added location for user \(location.userId)")
        locations[location.userId] = location
      } else {
        print("❌ [LocationShare] Failed to parse insert record")
      }
    case .update(let updateAction):
      if let location = parseLocationFromRecord(updateAction.record) {
        // Ignore own location
        guard location.userId != userId else {
          print("🚫 [LocationShare] Ignoring own location update")
          return
        }
        print("🔄 [LocationShare] Updated location for user \(location.userId)")
        locations[location.userId] = location
      } else {
        print("❌ [LocationShare] Failed to parse update record")
      }
    case .delete(let deleteAction):
      if let location = parseLocationFromRecord(deleteAction.oldRecord) {
        guard location.userId != userId else { return }
        print("➖ [LocationShare] Removed location for user \(location.userId)")
        locations.removeValue(forKey: location.userId)
      }
    case .select(_):
      break
    }
  }
  
  // Manually parse LocationShare from Supabase record
  private func parseLocationFromRecord(_ record: [String: Any]) -> LocationShare? {
    // Helper to extract actual value from AnyJSON type
    func extractValue<T>(_ key: String) -> T? {
      guard let value = record[key] else { return nil }
      
      // For AnyJSON enum, extract content using Mirror
      let mirror = Mirror(reflecting: value)
      
      // For enum, first child is the actual value
      if mirror.displayStyle == .enum, let (_, associatedValue) = mirror.children.first {
        return associatedValue as? T
      }
      
      // If directly castable
      return value as? T
    }
    
    guard let userId: Int = extractValue("user_id") else {
      print("❌ [LocationShare] user_id missing or wrong type: \(String(describing: record["user_id"]))")
      return nil
    }
    
    guard let planId: Int = extractValue("plan_id") else {
      print("❌ [LocationShare] plan_id missing or wrong type: \(String(describing: record["plan_id"]))")
      return nil
    }
    
    guard let latitude: Double = extractValue("latitude") else {
      print("❌ [LocationShare] latitude missing or wrong type: \(String(describing: record["latitude"]))")
      return nil
    }
    
    guard let longitude: Double = extractValue("longitude") else {
      print("❌ [LocationShare] longitude missing or wrong type: \(String(describing: record["longitude"]))")
      return nil
    }
    
    // display_name and profile_image_url are String or convertible types
    let displayName: String
    if let name: String = extractValue("display_name") {
      displayName = name
    } else if let value = record["display_name"] {
      displayName = String(describing: value)
    } else {
      print("❌ [LocationShare] display_name missing")
      return nil
    }
    
    let profileImageUrl: String? = extractValue("profile_image_url")
    let createdAt: String? = extractValue("created_at")
    let updatedAt: String? = extractValue("updated_at")
    let id: Int? = extractValue("id")
    
    return LocationShare(
      id: id,
      planId: planId,
      userId: userId,
      displayName: displayName,
      profileImageUrl: profileImageUrl,
      latitude: latitude,
      longitude: longitude,
      createdAt: createdAt,
      updatedAt: updatedAt
    )
  }
  
  // Disconnect
  func disconnect() async {
    await realtimeChannel?.unsubscribe()
    realtimeChannel = nil
    
    // Stop location monitoring
    locationManager.stopMonitoringLocation()
    
    // Stop periodic updates (just in case)
    locationUpdateTimer?.invalidate()
    locationUpdateTimer = nil
    
    await MainActor.run {
      self.isSharing = false
      self.locations.removeAll()
    }
  }
  
  // Start continuous location updates (works in background)
  private func startPeriodicLocationUpdates() {
    // Start LocationManager continuous monitoring
    locationManager.startMonitoringLocation()
    
    // Set callback for location updates
    locationManager.onLocationUpdate = { [weak self] coordinate in
      guard let self = self else { return }
      Task {
        await self.sendLocationUpdate(latitude: coordinate.latitude, longitude: coordinate.longitude)
      }
    }
    
    // Initial location send
    Task {
      await sendCurrentLocation()
    }
    
    print("✅ [LocationShare] Started background location updates")
  }
  
  // Get and send current location (for initial send)
  private func sendCurrentLocation() async {
    guard isSharing else { 
      print("⏸️ [LocationShare] Not sharing, skipping location update")
      return 
    }
    
    print("📍 [LocationShare] Getting initial location...")
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
  
  // Calculate distance between two points (meters)
  private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
    let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
    let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
    return fromLocation.distance(from: toLocation)
  }
}
