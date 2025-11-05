//
//  BlockedUser.swift
//  puctee
//
//  Created by kj on 11/4/25.
//

import Foundation

// MARK: - Blocked User Models

struct BlockUserCreate: Codable {
  let blockedUserId: Int
  let reason: String?
}

struct BlockedUserResponse: Codable, Identifiable {
  let id: Int
  let blockerUserId: Int
  let blockedUserId: Int
  let reason: String?
  let createdAt: Date
}
