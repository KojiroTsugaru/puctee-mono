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
  
  func handleArrival(planId: Int, isArrived: Bool?) {
    pendingPlanId = planId
    pendingArrivalResult = isArrived
  }
  
  func handlePenaltyApprovalRequest(requestId: Int) {
   pendingPenaltyRequestId = requestId
  }
  
  // clear when displaying UIs
  func consume() {
    pendingPlanId = nil
    pendingArrivalResult = nil
    pendingPenaltyRequestId = nil
  }
}

