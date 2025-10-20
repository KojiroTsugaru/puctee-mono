//
//  Penalty.swift
//  puctee
//
//  Created by kj on 5/14/25.
//

import Foundation

struct Penalty: Codable, Identifiable {
  let id: Int
  let content: String
  
  enum Status: String, Codable {
    case none
    case required
    case pendingApproval
    case completed
    case exempted
  }
}

extension Penalty {
  init(from response: PenaltyResponse) {
    self.id = response.id
    self.content = response.content
  }
}
