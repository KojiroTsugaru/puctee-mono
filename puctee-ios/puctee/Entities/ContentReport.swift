//
//  ContentReport.swift
//  puctee
//
//  Created by kj on 11/4/25.
//

import Foundation

// MARK: - Content Report Models

enum ContentReportType: String, Codable, CaseIterable {
  case penaltyRequest = "penalty_request"
  case plan
  case userProfile = "user_profile"
  
  var displayName: String {
    switch self {
    case .penaltyRequest: return "Penalty Request"
    case .plan: return "Plan"
    case .userProfile: return "User Profile"
    }
  }
}

enum ContentReportReason: String, Codable, CaseIterable {
  case spam
  case harassment
  case inappropriate
  case hateSpeech = "hate_speech"
  case violence
  case other
  
  var displayName: String {
    switch self {
    case .spam: return "Spam"
    case .harassment: return "Harassment"
    case .inappropriate: return "Inappropriate Content"
    case .hateSpeech: return "Hate Speech"
    case .violence: return "Violence"
    case .other: return "Other"
    }
  }
  
  var description: String {
    switch self {
    case .spam: return "Unwanted or repetitive content"
    case .harassment: return "Bullying or harassment"
    case .inappropriate: return "Offensive or inappropriate content"
    case .hateSpeech: return "Hateful or discriminatory content"
    case .violence: return "Violent or threatening content"
    case .other: return "Other violation"
    }
  }
}

struct ContentReportCreate: Codable {
  let reportedUserId: Int?
  let contentType: ContentReportType
  let contentId: Int?
  let reason: ContentReportReason
  let description: String?
}

struct ContentReportResponse: Codable, Identifiable {
  let id: Int
  let reporterUserId: Int
  let reportedUserId: Int?
  let contentType: String
  let contentId: Int?
  let reason: String
  let description: String?
  let status: String
  let createdAt: Date
  let reviewedAt: Date?
}
