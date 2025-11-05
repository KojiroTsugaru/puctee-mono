//
//  ModerationService.swift
//  puctee
//
//  Created by kj on 11/4/25.
//

import Foundation

enum ModerationError: Error {
  case badURL
  case networkError
  case decodingError
  case serverError(String)
}

final class ModerationService {
  static let shared = ModerationService()
  
  private init() {}
  
  // MARK: - Content Reporting
  
  /// Report inappropriate content
  func reportContent(_ report: ContentReportCreate) async throws {
    let urlString = Env.API.baseURL + "moderation/reports"
    guard let url = URL(string: urlString) else {
      throw ModerationError.badURL
    }
    
    let body = try JSONEncoder().encode(report)
    
    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.httpBody = body
    
    let (_, response) = try await APIClient.shared.request(for: req)
    
    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
      throw ModerationError.serverError("Failed to submit report")
    }
    
    print("✅ Content report submitted successfully")
  }
  
  /// Get all reports submitted by current user
  func getMyReports() async throws -> [ContentReportResponse] {
    let urlString = Env.API.baseURL + "moderation/reports/my-reports"
    guard let url = URL(string: urlString) else {
      throw ModerationError.badURL
    }
    
    let (data, _) = try await APIClient.shared.request(url: url, method: "GET")
    return try SnakeCaseJSONDecoder().decode([ContentReportResponse].self, from: data)
  }
  
  // MARK: - User Blocking
  
  /// Block a user
  func blockUser(userId: Int, reason: String? = nil) async throws {
    let urlString = Env.API.baseURL + "moderation/block"
    guard let url = URL(string: urlString) else {
      throw ModerationError.badURL
    }
    
    let blockRequest = BlockUserCreate(blockedUserId: userId, reason: reason)
    let body = try JSONEncoder().encode(blockRequest)
    
    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.httpBody = body
    
    let (_, response) = try await APIClient.shared.request(for: req)
    
    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
      throw ModerationError.serverError("Failed to block user")
    }
    
    print("🚫 User blocked successfully")
  }
  
  /// Unblock a user
  func unblockUser(userId: Int) async throws {
    let urlString = Env.API.baseURL + "moderation/block/\(userId)"
    guard let url = URL(string: urlString) else {
      throw ModerationError.badURL
    }
    
    var req = URLRequest(url: url)
    req.httpMethod = "DELETE"
    
    let (_, response) = try await APIClient.shared.request(for: req)
    
    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
      throw ModerationError.serverError("Failed to unblock user")
    }
    
    print("✅ User unblocked successfully")
  }
  
  /// Get list of blocked users
  func getBlockedUsers() async throws -> [User] {
    let urlString = Env.API.baseURL + "moderation/blocked-users"
    guard let url = URL(string: urlString) else {
      throw ModerationError.badURL
    }
    
    let (data, _) = try await APIClient.shared.request(url: url, method: "GET")
    return try SnakeCaseJSONDecoder().decode([User].self, from: data)
  }
  
  /// Check if a user is blocked
  func isUserBlocked(userId: Int) async throws -> Bool {
    let urlString = Env.API.baseURL + "moderation/is-blocked/\(userId)"
    guard let url = URL(string: urlString) else {
      throw ModerationError.badURL
    }
    
    let (data, _) = try await APIClient.shared.request(url: url, method: "GET")
    let response = try JSONDecoder().decode([String: Bool].self, from: data)
    return response["is_blocked"] ?? false
  }
}
