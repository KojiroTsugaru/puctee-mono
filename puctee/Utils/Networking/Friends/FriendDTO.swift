//
//  FriendDTO.swift
//  puctee
//
//  Created by kj on 5/16/25.
//

import Foundation

/// Model representing a friend invitation
struct FriendInvite: Identifiable, Codable, Equatable {
  let id: Int
  let senderId: Int
  let receiverId: Int
/// Invitation status ("pending", "accepted", "declined")
  let status: String
  let createdAt: Date?
}

/// Enum for handling invitation status in a type-safe manner
enum FriendInviteStatus: String, Codable {
  case pending
  case accepted
  case declined
}
