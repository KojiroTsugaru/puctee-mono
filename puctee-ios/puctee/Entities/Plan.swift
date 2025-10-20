//
//  Plan.swift
//  puctee
//
//  Created by kj on 5/9/25.
//

import Foundation

struct Plan: Codable, Equatable {
  static func == (lhs: Plan, rhs: Plan) -> Bool {
    lhs.id == rhs.id
  }
  
  let id: Int
  let title: String
  let startTime: Date
  let status: Status
  let location: Location
  let createdAt: Date
  let updatedAt: Date?
  let participants: [User]
  let penalties: [Penalty]?

  enum Status: String, Codable {
    case upcoming, ongoing, completed, cancelled
  }
}

extension Plan {
  init(from response: PlanResponse) {
    self.id = response.id
    self.title = response.title
    self.startTime = response.startTime
    // Map the response status. If mapping is not possible, fall back to .upcoming
    self.status = Status(rawValue: response.status) ?? .upcoming
    self.createdAt = response.createdAt
    self.updatedAt = response.updatedAt
    self.participants = response.participants
    
    if let locationResp = response.location {
      self.location = Location(from: locationResp)
    } else {
      fatalError("location is nil")
    }
    // Convert penalty if it exists, otherwise nil
    if let penResp = response.penalties {
      self.penalties = penResp.map { Penalty(from: $0) }
    } else {
      self.penalties = nil
    }
  }
}
