//
//  TrustStats.swift
//  puctee
//
//  Created by kj on 6/1/25.
//

struct TrustStats: Codable, Equatable {
  let totalPlans: Int
  let latePlans: Int
  let onTimeStreak: Int
  let bestOnTimeStreak: Int
  let lastArrivalStatus: String?
  let trustLevel: Double
}
