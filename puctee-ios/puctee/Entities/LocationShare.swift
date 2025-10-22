//
//  LocationShare.swift
//  puctee
//
//  Created by kj on 9/7/25.
//

import Foundation

struct LocationShare: Codable, Identifiable, Equatable {
  let id: Int?
  let planId: Int
  let userId: Int
  let displayName: String
  let profileImageUrl: String?
  let latitude: Double
  let longitude: Double
  let createdAt: String?
  let updatedAt: String?
  
  enum CodingKeys: String, CodingKey {
    case id
    case planId = "plan_id"
    case userId = "user_id"
    case displayName = "display_name"
    case profileImageUrl = "profile_image_url"
    case latitude
    case longitude
    case createdAt = "created_at"
    case updatedAt = "updated_at"
  }
}
