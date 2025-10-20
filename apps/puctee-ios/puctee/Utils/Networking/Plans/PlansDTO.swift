//
//  PlansDTO.swift
//  puctee
//
//  Created by kj on 5/15/25.
//

import Foundation

struct LocationCreate: Codable {
  let name: String
  let latitude: Double
  let longitude: Double
}

struct PenaltyCreate: Codable {
  let content: String
}

struct CreatePlanRequest: Codable {
  let title: String
  let penalty: PenaltyCreate?
  let start_time: Date
  let location: LocationCreate
  let participants: [Int]?
}

struct PenaltyResponse: Codable {
  let content: String
  let id: Int
  let planId: Int
  let userId: Int
}

struct LocationResponse: Codable {
  let id: Int
  let name: String
  let latitude: Double
  let longitude: Double
}

struct PlanUpdateRequest: Codable {
  let title: String?
  let status: Plan.Status?
  let start_time: String?           // ISO8601 format
  let penalty: PenaltyCreate?
  let location: LocationCreate?
  let participants: [Int]?          // User ID list
}

struct PlanResponse: Codable {
  let title: String
  let startTime: Date
  let id: Int
  let status: String
  let createdAt: Date
  let updatedAt: Date?
  let participants: [User]
  let locations: [LocationResponse]
  let penalties: [PenaltyResponse]?
}

extension PlanResponse {
  var location: LocationResponse? { locations.first }
}

struct LocationCheckRequest: Codable {
  let latitude: Double
  let longitude: Double
}

struct LocationCheckResponse: Codable {
  let isArrived: Bool
  let distance: Float
}

struct PlanInviteResponse: Codable {
  let id: Int
  let status: String
  let plan: PlanResponse
}

struct PenaltyStatusResponse: Codable {
  let planId: Int
  let userId: Int
  let penaltyStatus: Penalty.Status
  let penaltyCompletedAt: Date?
}

struct PenaltyApprovalRequest: Codable {
  let comment: String?
  let proof_image_data: String?
}

struct PenaltyApprovalRequestResponse: Identifiable, Codable {
  enum Status: String, Codable {
    case pending
    case approved
    case declined
  }
  
  let id: Int
  let planId: Int
  let penaltyUserId: Int
  let penaltyName: String
  let comment: String?
  let proofImageUrl: URL?
  let status: PenaltyApprovalRequestResponse.Status
  let approverUserId: Int?
  let approvedAt: Date?
  let createdAt: Date
  let updatedAt: Date?
}

struct ValidationResponse: Codable {
  let valid: Bool
  let userInfo: UserInfo?
  let error: String?
  
  struct UserInfo: Codable {
    let userId: Int
    let displayName: String
    let profileImageUrl: String?
    
    enum CodingKeys: String, CodingKey {
      case userId = "user_id"
      case displayName = "display_name"
      case profileImageUrl = "profile_image_url"
    }
  }
}
