//
//  LocationShare.swift
//  puctee
//
//  Created by kj on 9/7/25.
//

import Foundation

struct LocationShare: Codable, Identifiable {
  let id: Int?
  let planId: Int
  let userId: Int
  let displayName: String
  let profileImageUrl: String?
  let latitude: Double
  let longitude: Double
  let createdAt: String?
  let updatedAt: String?
}
