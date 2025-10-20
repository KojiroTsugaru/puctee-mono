//
//  APIClient.swift
//  puctee
//
//  Created by kj on 5/13/25.
//

import Foundation

actor APIClient {
  static let shared = APIClient()
  
  /// Build and execute a request with authentication and return the response data
  func request(
    url: URL,
    method: String,
    body: Data? = nil,
    debugMode: Bool = true
  ) async throws -> (Data, HTTPURLResponse) {
    var req = URLRequest(url: url)
    req.httpMethod = method
    req.httpBody = body
    
    // Always set authentication information
    try await AuthService.shared.authorizedRequest(&req)
    
    print("ℹ️INFOℹ️: 🌐 REQUESTED \(String(describing: url))")
    
    //  Normal URLSession
    let (data, resp) = try await URLSession.shared.data(for: req)
    
    // Error handling
    guard let http = resp as? HTTPURLResponse else {
      throw AuthError.invalidResponse
    }
    
    // debug mode
    if debugMode {
      print("ℹ️INFOℹ️: status code: \(http.statusCode)")
      if let body = String(data: data, encoding: .utf8) {
        print("ℹ️INFOℹ️: body: \(body)")
      }
    }
    
    guard (200...299).contains(http.statusCode) else {
      if let body = String(data: data, encoding: .utf8) {
        print("‼️ERROR‼️: \(String(describing: req.url))")
        print("‼️ERROR‼️:", body)
      }
      throw AuthError.serverError(http.statusCode)
    }
    
    print("ℹ️INFOℹ️: ✅ SUCESS \(String(describing: url))")
    return (data, http)
  }
  
  /// Execute a fully-configured URLRequest: inject Authorization and execute.
  func request(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
    var req = request
    // 1) Inject or refresh bearer token
    try await AuthService.shared.authorizedRequest(&req)
    
    print("ℹ️INFOℹ️: 🌐 REQUESTED \(String(describing: req.url!.absoluteString))")
    // 2) Execute
    let (data, resp) = try await URLSession.shared.data(for: req)
    
    // 3) Handle exception
    guard let http = resp as? HTTPURLResponse else {
      throw AuthError.invalidResponse
    }
    guard (200...299).contains(http.statusCode) else {
      if let body = String(data: data, encoding: .utf8) {
        print("‼️ERROR‼️: \(String(describing: req.url))")
        print("‼️ERROR‼️:", body)
      }
      throw AuthError.serverError(http.statusCode)
    }
    
    print("ℹ️INFOℹ️: ✅ SUCESS \(String(describing: request.url!.absoluteString))")
    return (data, http)
  }
}

extension APIClient {
  /// Inject  bearer token but not making a request
  func makeAuthorizedRequest(
    url: URL,
    method: String,
    body: Data? = nil,
    headers: [String: String] = [:]
  ) async throws -> URLRequest {
    var req = URLRequest(url: url)
    req.httpMethod = method
    req.httpBody = body
    headers.forEach { k, v in req.setValue(v, forHTTPHeaderField: k) }
    try await AuthService.shared.authorizedRequest(&req)
    return req
  }
}
