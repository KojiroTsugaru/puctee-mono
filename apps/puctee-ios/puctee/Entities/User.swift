//
//  User.swift
//  puctee
//
//  Created by kj on 5/8/25.
//

import Foundation

struct User: Codable, Identifiable, Equatable {
  let id: Int
  let email: String
  let displayName: String
  let username: String
  var profileImageUrl: URL?
}

extension User {
  init(from all: UserAll) {
    self.id = all.id
    self.email = all.email
    self.displayName = all.displayName
    self.username = all.username
    self.profileImageUrl = all.profileImageUrl
  }
}
