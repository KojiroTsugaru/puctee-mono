//
//  TrustStatsManager.swift
//  puctee
//
//  Created by kj on 6/1/25.
//

import Observation
import SwiftUI

@Observable class TrustStatsManager {
  var trustStats: TrustStats?
  
  /// fetch current user's trust stats
  func fetchTrustStats() async {
    do {
      let stats = try await UserService.shared.fetchTrustStats()
      
      await MainActor.run {
        self.trustStats = stats
      }
    } catch {
      print("Fetch trust stats failed: \(error)")
    }
  }
}

// MARK: Environment Key
extension EnvironmentValues {
  var trustStatsManager: TrustStatsManager {
    get {
      self[TrustStatsManagerKey.self]
    } set {
      self[TrustStatsManagerKey.self] = newValue
    }
  }
}

private struct TrustStatsManagerKey: EnvironmentKey {
  static let defaultValue: TrustStatsManager = TrustStatsManager()
}
