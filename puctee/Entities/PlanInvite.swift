//
//  PlanInvites.swift
//  puctee
//
//  Created by kj on 5/17/25.
//

import Foundation

struct PlanInvite: Codable, Identifiable {
  let id: Int
  /// pending, accepted, rejected
  let status: String
  let plan: Plan
}

extension PlanInvite {
  init(from response: PlanInviteResponse) {
    self.id = response.id
    self.status = response.status
    self.plan = .init(from: response.plan)
  }
}
