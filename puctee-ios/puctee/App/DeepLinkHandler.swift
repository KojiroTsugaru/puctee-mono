//
//  DeepLinkHandler.swift
//  puctee
//
//  Created by kj on 8/16/25.
//

import Combine

final class DeepLinkHandler: ObservableObject {
  static let shared = DeepLinkHandler()
  @Published var pendingPlanId: Int?
  @Published var pendingArrivalResult: Bool?
  @Published var pendingPenaltyRequestId: Int?
  @Published var pendingPrevTrustLevel: Double?
  @Published var pendingNewTrustLevel: Double?
  
  func handleArrival(planId: Int, isArrived: Bool?, prevTrustLevel: Double? = nil, newTrustLevel: Double? = nil) {
    pendingPlanId = planId
    pendingArrivalResult = isArrived
    pendingPrevTrustLevel = prevTrustLevel
    pendingNewTrustLevel = newTrustLevel
  }
  
  func handlePenaltyApprovalRequest(requestId: Int) {
   pendingPenaltyRequestId = requestId
  }
  
  // clear when displaying UIs
  func consume() {
    pendingPlanId = nil
    pendingArrivalResult = nil
    pendingPenaltyRequestId = nil
    pendingPrevTrustLevel = nil
    pendingNewTrustLevel = nil
  }
}

