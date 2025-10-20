//
//  LocationManager.swift
//  puctee
//
//  Created by kj on 8/18/25.
//

import Foundation
import CoreLocation

final class LocationManager: NSObject, CLLocationManagerDelegate {
  static let shared = LocationManager()
  
  private let manager = CLLocationManager()
  
  // 直近の現在地（delegateで更新）
  private(set) var userLocation: CLLocation?
  /// 即参照用（未取得なら nil）
  var userCoordinate: CLLocationCoordinate2D? { userLocation?.coordinate }
  
  // 複数同時要求を束ねるための保留
  private struct PendingRequest {
    let id: UUID
    let continuation: CheckedContinuation<CLLocationCoordinate2D, Error>
    let timeoutWorkItem: DispatchWorkItem
  }
  private var pendingRequests: [UUID: PendingRequest] = [:]
  
  private override init() {
    super.init()
    manager.delegate = self
    manager.allowsBackgroundLocationUpdates = true
    manager.pausesLocationUpdatesAutomatically = true
    manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
  }
  
  // 権限リクエスト（BG測位のため Always 推奨）
  func requestAuthorization() {
    manager.requestAlwaysAuthorization()
  }
  
  // 現在地を即時測位して返す（キャッシュが良好ならそれを返す）
  enum LocationError: Error { case servicesDisabled, notAuthorized, timeout, noLocation }
  
  func getUserCoordinate(timeout: TimeInterval = 12,
                         desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyHundredMeters)
  async throws -> CLLocationCoordinate2D
  {
    guard CLLocationManager.locationServicesEnabled() else {
      throw LocationError.servicesDisabled
    }
    let status = manager.authorizationStatus
    guard status == .authorizedAlways || status == .authorizedWhenInUse else {
      throw LocationError.notAuthorized
    }
    
    // 新鮮で十分な精度のキャッシュがあれば返す
    if let loc = userLocation,
       Date().timeIntervalSince(loc.timestamp) < 5,
       loc.horizontalAccuracy > 0,
       loc.horizontalAccuracy <= desiredAccuracy {
      return loc.coordinate
    }
    
    manager.desiredAccuracy = desiredAccuracy
    
    return try await withCheckedThrowingContinuation { (cont: CheckedContinuation<CLLocationCoordinate2D, Error>) in
      let id = UUID()
      let timeoutItem = DispatchWorkItem { [weak self] in
        guard let self else { return }
        if let pending = self.pendingRequests.removeValue(forKey: id) {
          pending.continuation.resume(throwing: LocationError.timeout)
        }
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + timeout, execute: timeoutItem)
      
      pendingRequests[id] = PendingRequest(id: id, continuation: cont, timeoutWorkItem: timeoutItem)
      manager.requestLocation() // ワンショット測位
    }
  }
  
  /// 現在地のキャッシュ更新だけ行いたいとき
  func refreshUserLocation(desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyHundredMeters) {
    manager.desiredAccuracy = desiredAccuracy
    manager.requestLocation()
  }
  
  // MARK: - CLLocationManagerDelegate
  
  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    if manager.authorizationStatus != .authorizedAlways {
      print("⚠️ Background arrival check を安定させるには Always 権限が推奨です。")
    }
  }
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    let best = locations.last ?? manager.location
    
    if let loc = best, loc.horizontalAccuracy > 0 {
      userLocation = loc
      // ペンディングを一括解決
      guard !pendingRequests.isEmpty else { return }
      let reqs = pendingRequests
      pendingRequests.removeAll()
      for (_, r) in reqs {
        r.timeoutWorkItem.cancel()
        r.continuation.resume(returning: loc.coordinate)
      }
    } else {
      // 位置が取れなかった場合
      guard !pendingRequests.isEmpty else { return }
      let reqs = pendingRequests
      pendingRequests.removeAll()
      for (_, r) in reqs {
        r.timeoutWorkItem.cancel()
        r.continuation.resume(throwing: LocationError.noLocation)
      }
    }
  }
  
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    print("Location error:", error)
    guard !pendingRequests.isEmpty else { return }
    let reqs = pendingRequests
    pendingRequests.removeAll()
    for (_, r) in reqs {
      r.timeoutWorkItem.cancel()
      r.continuation.resume(throwing: error)
    }
  }
}
