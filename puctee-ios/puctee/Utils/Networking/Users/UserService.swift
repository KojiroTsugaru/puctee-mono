//
//  UserService.swift
//  puctee
//
//  Created by kj on 5/12/25.
//

import Foundation
import UIKit

enum UserServiceError: Error {
  case missingToken
  case invalidResponse(statusCode: Int)
}

class UserService {
  static let shared = UserService()
  private init() {}
  
  /// Get current user information
  func fetchCurrentUser() async throws -> User {
    // 1. Create a URLRequest and set the Authorization header
    let urlString = Env.API.baseURL + "users/me"
    guard let url = URL(string: urlString) else {
      throw URLError(.badURL)
    }
    
    // 2. Execute the request
    let (data, _) = try await APIClient.shared.request(url: url, method: "GET")
    
    // 4. Decode JSON
    let user = try SnakeCaseJSONDecoder().decode(User.self, from: data)
    return user
  }
  
  /// fetch user by id
  func fetchUser(id: Int) async throws -> User? {
    let urlString = Env.API.baseURL + "users/\(id)"
    guard let url = URL(string: urlString) else {
      throw URLError(.badURL)
    }

    let (data, _) = try await APIClient.shared.request(url: url, method: "GET")
    
    let user = try SnakeCaseJSONDecoder().decode(User.self, from: data)
    print("Fetched User \(id) Successfully: ", user)
    return user
  }
  /// Convert the image to JPEG and send it as multipart/form-data
  func uploadProfileImage(imageData: Data) async throws -> ProfileImageResponse {
    let urlString = Env.API.baseURL + "users/profile-image"
    guard let url = URL(string: urlString) else {
      throw URLError(.badURL)
    }
    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    
    // Create a unique Boundary
    let boundary = "Boundary-\(UUID().uuidString)"
    req.setValue("multipart/form-data; boundary=\(boundary)",
                 forHTTPHeaderField: "Content-Type")
    
    // 3) Build body
    var body = Data()
    body.append("--\(boundary)\r\n")
    // Note: name="file" exactly
    body.append("Content-Disposition: form-data; name=\"file\"; filename=\"profile.jpg\"\r\n")
    body.append("Content-Type: image/jpeg\r\n\r\n")
    body.append(imageData)
    body.append("\r\n")
    body.append("--\(boundary)--\r\n")
    
    req.httpBody = body
    
    // Execute the request
    let (data, _) = try await APIClient.shared.request(for: req)
    return try SnakeCaseJSONDecoder().decode(ProfileImageResponse.self, from: data)
  }
  
  /// User search method
  func searchUsers(query: String) async throws -> [User] {
    guard !query.isEmpty else { return [] }
    
    // URL construction
    let baseURL = Env.API.baseURL + "users/filter"
    guard let url = URL(string: "\(baseURL)?query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") else {
      throw URLError(.badURL)
    }
    
    // Execute network request
    let (data, _) = try await APIClient.shared.request(url: url, method: "GET")
    
    // For debugging: check the contents of the response
    if let jsonString = String(data: data, encoding: .utf8) {
      print("Response JSON: \(jsonString)")
    }
    
    // Json decode
    let searchResults = try SnakeCaseJSONDecoder().decode([User].self, from: data)
    return searchResults
  }
  
  /// update push token
  func updatePushToken(token: String) async throws {
    guard !token.isEmpty else { return }
    
    var components = URLComponents(string: Env.API.baseURL + "users/me/push-token")!
    components.queryItems = [
      URLQueryItem(name: "push_token", value: token)
    ]
    
    guard let url = components.url else {
      throw URLError(.badURL)
    }
    
    // Create request body
    var request = URLRequest(url: url)
    request.httpMethod = "PUT"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    let parameters = ["push_token": token]
    request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
    
    let (_, _) = try await APIClient.shared.request(for: request)
  }
  
  /// fetch user's trust stats
  func fetchTrustStats() async throws -> TrustStats {
    let urlString = Env.API.baseURL + "users/me/trust-stats"
    guard let url = URL(string: urlString) else {
      throw URLError(.badURL)
    }
    
    let (data, _) = try await APIClient.shared.request(url: url, method: "GET")
    return try SnakeCaseJSONDecoder().decode(TrustStats.self, from: data)
  }
  
  /// delete current user account
  func deleteAccount() async throws {
    let urlString = Env.API.baseURL + "users/me"
    guard let url = URL(string: urlString) else {
      throw URLError(.badURL)
    }
    
    let (_, _) = try await APIClient.shared.request(url: url, method: "DELETE")
  }
}

extension Data {
  mutating func append(_ string: String) {
    if let d = string.data(using: .utf8) {
      append(d)
    }
  }
}
