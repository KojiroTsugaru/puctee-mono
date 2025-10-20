//
//  PlansService.swift
//  puctee
//
//  Created by kj on 5/15/25.
//

import Foundation

actor PlanService {
  static let shared = PlanService()
  private let encoder: JSONEncoder
  
  private init() {
    encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
  }
  
  /// Create a new plan and return the Plan returned from the server
  func createPlan(planRequest: CreatePlanRequest) async throws -> Plan {
    let urlString = Env.API.baseURL + "plans/create"
    guard let url = URL(string: urlString) else {
      throw AuthError.badURL
    }
    
    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let bodyData = try encoder.encode(planRequest)
    req.httpBody = bodyData
    
    let (data, _) = try await APIClient.shared.request(for: req)
    print(String(data: data, encoding: .utf8)!)
    
    let response = try SnakeCaseJSONDecoder().decode(PlanResponse.self, from: data)
    return Plan(from: response)
  }
  
  /// Fetch a Plan by specifying its Status
  func fetchPlans(by status: [Plan.Status]) async throws -> [Plan] {
    // Build the JSON body
    let body: [String: Any] = [
      "skip": 0,
      "limit": 20,
      "plan_status": status.map { $0.rawValue }
    ]
    let urlString = "\(Env.API.baseURL)plans/list"
    guard let url = URL(string: urlString) else {
      throw AuthError.badURL
    }
    let jsonData = try JSONSerialization.data(withJSONObject: body)
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = jsonData
    
    let (data, _) = try await APIClient.shared.request(for: request)
    let result = try SnakeCaseJSONDecoder().decode([PlanResponse].self, from: data)
    let plans = result.map(Plan.init(from:))
    return plans
  }
  
  /// Fetch a Plan by specifying its id
  func fetchPlan(id: Int) async throws -> Plan {
    // Build query parameters
    let url = URL(string: Env.API.baseURL + "plans/\(id)")!
    
    let (data, _) = try await APIClient.shared.request(url: url, method: "GET")
    
    let response = try SnakeCaseJSONDecoder().decode(PlanResponse.self, from: data)
    let plan = Plan(from: response)
    return plan
  }
  
  /// Check if you have arrived at your destination
  func checkArrival(planId: Int, locationCheckReqest: LocationCheckRequest) async throws -> Bool {
    let url = URL(string: "\(Env.API.baseURL)plans/\(planId)/arrival")!
    let body = try JSONEncoder().encode(locationCheckReqest)
    
    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.httpBody = body
    
    let (data, _) = try await APIClient.shared.request(for: req)
    let response = try SnakeCaseJSONDecoder().decode(LocationCheckResponse.self, from: data)
    return response.isArrived
  }
  
  func updatePlan(id: Int, updateRequest: PlanUpdateRequest) async throws -> Plan {
    // 1. Generate URL and request
    let urlString = Env.API.baseURL + "plans/\(id)"
    guard let url = URL(string: urlString) else {
      throw AuthError.badURL
    }
    
    let body = try? JSONEncoder().encode(updateRequest)
    let (data, _) = try await APIClient.shared.request(url: url, method: "PUT", body: body)
    
    // 6. Decode the response
    let response = try SnakeCaseJSONDecoder().decode(PlanResponse.self, from: data)
    let updatedPlan = Plan(from: response)
    return updatedPlan
  }
  
  /// delete
  func deletePlan(id: Int) async throws {
    // 1. Generate URL and request
    let urlString = Env.API.baseURL + "plans/\(id)"
    guard let url = URL(string: urlString) else {
      throw AuthError.badURL
    }
    
    let (_, _) = try await APIClient.shared.request(url: url, method: "DELETE")
  }
  
  /// Fetch only planInvites with "pending" status
  func fetchPlanInvites() async throws -> [PlanInvite] {
    let urlString = Env.API.baseURL + "plans/invites/list"
    guard let url = URL(string: urlString) else {
      throw AuthError.badURL
    }
    
    let (data, _) = try await APIClient.shared.request(url: url, method: "GET")
    
    let response = try SnakeCaseJSONDecoder().decode([PlanInviteResponse].self, from: data)
    return response.map { PlanInvite.init(from: $0) }
  }
  
  /// Fetch PlanInvite by specifying Status
  /// If Status is not specified, it will default to returning only PlanInvites with "pending" status.
  func updatePlanInvite(inviteId: Int, newStatus: String) async throws -> PlanInvite {
    let urlString = Env.API.baseURL + "plans/invites/\(inviteId)"
    guard var comps = URLComponents(string: urlString) else {
      throw AuthError.badURL
    }
    
    comps.queryItems = [
      URLQueryItem(name: "status", value: newStatus)
    ]
    guard let url = comps.url else {
      throw AuthError.badURL
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "PUT"
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    
    let (data, _) = try await APIClient.shared.request(for: request)
    
    let response = try SnakeCaseJSONDecoder().decode(PlanInviteResponse.self, from: data)
    return PlanInvite(from: response)
  }
}

// MARK: Penalty
extension PlanService {
  /// send penalty approval request to to other participants
  func requestPenaltyApproval(planId: Int, request: PenaltyApprovalRequest, isSolo: Bool) async throws {
    let urlString = Env.API.baseURL + (isSolo ? "plans/\(planId)/penalty-approval-request-solo" : "plans/\(planId)/penalty-approval-request")
    guard let url = URL(string: urlString) else {
      throw AuthError.badURL
    }
    
    let body = try JSONEncoder().encode(request)
    
    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.httpBody = body
    
    let (_, _) = try await APIClient.shared.request(for: req)
  }
  
  /// approve penalty approval request
  func fetchCurrentUserPenaltyStatus(planId: Int) async throws -> Penalty.Status? {
    let urlString = Env.API.baseURL + "plans/\(planId)/me/penalty-status"
    guard let url = URL(string: urlString) else {
      throw AuthError.badURL
    }
    
    let (data, _) = try await APIClient.shared.request(url: url, method: "GET")
    let response = try SnakeCaseJSONDecoder().decode(PenaltyStatusResponse.self, from: data)
    return response.penaltyStatus
  }
  
  func fetchPenaltyApprovalRequest(requestId: Int) async throws -> PenaltyApprovalRequestResponse {
    let urlString = Env.API.baseURL + "plans/penalty-approval-requests/\(requestId)"
    guard let url = URL(string: urlString) else {
      throw AuthError.badURL
    }
    
    let (data, _) = try await APIClient.shared.request(url: url, method: "GET")
    return try SnakeCaseJSONDecoder().decode(PenaltyApprovalRequestResponse.self, from: data)
  }
  
  func fetchAllPenaltyApprovalRequest(planId: Int) async throws -> [PenaltyApprovalRequestResponse] {
    let urlString = Env.API.baseURL + "plans/\(planId)/penalty-approval-requests"
    
    guard let url = URL(string: urlString) else {
      throw AuthError.badURL
    }
    
    let (data, _) = try await APIClient.shared.request(url: url, method: "GET")
    return try SnakeCaseJSONDecoder().decode([PenaltyApprovalRequestResponse].self, from: data)
  }
  
  func approvePenaltyRequest(planId: Int, requestId: Int) async throws {
    let urlString = Env.API.baseURL + "plans/\(planId)/penalty-approval/\(requestId)"
    guard let url = URL(string: urlString) else {
      throw AuthError.badURL
    }
    
    let (_, _) = try await APIClient.shared.request(url: url, method: "POST")
  }
  
  func declinePenaltyRequest(planId: Int, requestId: Int) async throws {
    let urlString = Env.API.baseURL + "plans/\(planId)/penalty-decline/\(requestId)"
    guard let url = URL(string: urlString) else {
      throw AuthError.badURL
    }
    
    let (_, _) = try await APIClient.shared.request(url: url, method: "POST")
  }
}


// MARK: Websocket

extension PlanService {
  // // AWS Lambda APIエンドポイントを呼び出してユーザーが本当にプランに存在するか検証
  func validateAccess(planId: Int, userId: Int) async throws -> Bool {
    let urlString = Env.API.baseURL + "plans/plans/location/validate-location-share"
    guard let url = URL(string: urlString) else {
      throw AuthError.badURL
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    let body = [
      "plan_id": planId,
      "user_id": userId
    ]
    
    request.httpBody = try JSONSerialization.data(withJSONObject: body)
    
    let (data, _) = try await APIClient.shared.request(for: request)
    let response = try SnakeCaseJSONDecoder().decode(ValidationResponse.self, from: data)
    return response.valid
  }
}
