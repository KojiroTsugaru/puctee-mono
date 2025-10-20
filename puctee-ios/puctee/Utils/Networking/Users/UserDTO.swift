//
//  UserDTO.swift
//  puctee
//
//  Created by kj on 5/12/25.
//

import Foundation

struct UserAll: Codable {
  let id: Int
  let email: String
  let displayName: String
  let username: String
  let hashedPassword: String
  let isActive: Bool
  let pushToken: String?
  let profileImageUrl: URL?
  let trustStats: TrustStats
}

struct ProfileImageResponse: Codable {
  let message: String
  let url: URL
}

