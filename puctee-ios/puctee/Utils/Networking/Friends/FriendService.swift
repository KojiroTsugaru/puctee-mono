//
//  FriendService.swift
//  puctee
//
//  Created by kj on 5/16/25.
//

import Foundation

enum FriendServiceError: Error {
  case invalidURL
  case invalidResponse(statusCode: Int)
  case inviteAlreadyExist(statusCode: Int)
}

/// Service that summarizes API calls related to friends
class FriendService {
  static let shared = FriendService()
  private init() {}
  
  let baseUrl = Env.API.baseURL + "friends/"
  
  /// Get a list of friends
  func fetchFriends() async throws -> [User] {
    let urlString = self.baseUrl + "list"
    guard let url = URL(string: urlString) else {
      throw FriendServiceError.invalidURL
    }
    let (data, _) = try await APIClient.shared.request(url: url, method: "GET")
    
    let friends = try SnakeCaseJSONDecoder().decode([User].self, from: data)
    print("Fetched Friends Successfully: ", friends)
    return friends
  }
  
  /// Get a list of friend invitations
  func fetchReceivedInvites() async throws -> [FriendInvite] {
    let urlString = self.baseUrl + "friend-invites/received"
    guard let url = URL(string: urlString) else {
      throw FriendServiceError.invalidURL
    }
    let (data, _) = try await APIClient.shared.request(url: url, method: "GET")
    return try SnakeCaseJSONDecoder().decode([FriendInvite].self, from: data)
  }
  
  /// Get a list of sent friend requests
  func fetchSentInvites() async throws -> [FriendInvite] {
    let urlString = self.baseUrl + "friend-invites/sent"
    guard let url = URL(string: urlString) else {
      throw FriendServiceError.invalidURL
    }
    let (data, _) = try await APIClient.shared.request(url: url, method: "GET")
    return try SnakeCaseJSONDecoder().decode([FriendInvite].self, from: data)
  }
  
  /// Send a friend invitation
  func sendInvite(to receiverId: Int) async throws -> FriendInvite {
    let urlString = self.baseUrl + "friend-invites"
    guard let url = URL(string: urlString) else {
      throw FriendServiceError.invalidURL
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let body = ["receiver_id": receiverId]
    request.httpBody = try JSONEncoder().encode(body)
    
    let (data, _) = try await APIClient.shared.request(for: request)
    return try SnakeCaseJSONDecoder().decode(FriendInvite.self, from: data)
  }
  
  /// Accept a friend invitation
  func acceptInvite(inviteId: Int) async throws {
    let urlString = self.baseUrl + "friend-invites/\(inviteId)/accept"
    guard let url = URL(string: urlString) else {
      throw FriendServiceError.invalidURL
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    
    let (_, response) = try await APIClient.shared.request(for: request)
    guard (200...299).contains(response.statusCode) else {
      throw FriendServiceError.invalidResponse(statusCode: response.statusCode)
    }
  }
  
  /// Decline a friend invitation
  func declineInvite(inviteId: Int) async throws {
    let urlString = self.baseUrl + "friend-invites/\(inviteId)/decline"
    guard let url = URL(string: urlString) else {
      throw FriendServiceError.invalidURL
    }
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    
    let (_, response) = try await APIClient.shared.request(for: request)
    guard (200...299).contains(response.statusCode) else {
      throw FriendServiceError.invalidResponse(statusCode: response.statusCode)
    }
  }
  
  /// Remove a friend
  func removeFriend(friendId: Int) async throws {
    let urlString = self.baseUrl + "\(friendId)"
    guard let url = URL(string: urlString) else {
      throw FriendServiceError.invalidURL
    }
    var request = URLRequest(url: url)
    request.httpMethod = "DELETE"
    
    let (_, response) = try await APIClient.shared.request(for: request)
    guard (200...299).contains(response.statusCode) else {
      throw FriendServiceError.invalidResponse(statusCode: response.statusCode)
    }
  }
}
