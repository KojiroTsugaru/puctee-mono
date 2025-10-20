//
//  ModalRoute.swift
//  puctee
//
//  Created by kj on 8/21/25.
//

import Foundation

enum ModalRoute: Equatable, Identifiable {
  case arrival(planId: Int, isArrived: Bool?)
  case penaltyApprovalRequest(requestId: Int)
  
  var id: String {
    switch self {
      case let .arrival(pid, isArrived): return "arrival-\(pid)-\(isArrived?.description ?? "nil")"
      case let .penaltyApprovalRequest(requestId: requestId): return "penalty-\(requestId)"
    }
  }
  
  // Penalty > Arrival
  var priority: Int {
    switch self {
      case .arrival: return 1
      case .penaltyApprovalRequest: return 2
    }
  }
}
