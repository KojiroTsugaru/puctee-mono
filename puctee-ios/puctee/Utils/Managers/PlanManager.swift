//
//  PlanManager.swift
//  puctee
//
//  Created by kj on 5/10/25.
//

import Foundation
import Observation
import SwiftUI
import CoreLocation

@Observable class PlanManager {
  // For WS integration
  private let wsCoordinator: LocationShareWSCoordinator
  
  // store all plans
  var myPlans: [Plan] = [] {
    didSet {
      wsCoordinator.updatePlans(myPlans)
    }
  }
  
  // upcoming
  var upcomingPlans: [Plan] {
    myPlans.filter { $0.status == .upcoming && $0.startTime > .now }
  }
  
  // ongoing
  var ongoingPlans: [Plan] {
    myPlans.filter { $0.status == .ongoing }
  }
  
  // completed, cancelled
  var pastPlans: [Plan] {
    myPlans.filter {
      $0.status == .completed ||
      $0.status == .cancelled
    }
  }
  
  // invites
  var planInvites: [PlanInvite] = []
  
  /// Timer for checking plan start time 15 minutes in advance
  private var startCheckTimer: Timer?
  
  init(accountManager: AccountManager) {
    self.wsCoordinator = LocationShareWSCoordinator(accountManager: accountManager)
  }
  
  func getWebsocket(planId: Int) -> LocationShareWSManager? {
    wsCoordinator.getWebsocket(planId: planId)
  }
  
  /// create
  func createPlan(
    title: String,
    penaltyContent: String?,
    start_time: Date,
    locationName: String,
    coordinates: CLLocationCoordinate2D,
    participants: [Int]?
  ) async throws {
    let location = LocationCreate(name: locationName,
                                  latitude: coordinates.latitude,
                                  longitude: coordinates.longitude)
    var penalty: PenaltyCreate? {
      guard let content = penaltyContent else { return nil }
      return PenaltyCreate(content: content)
    }
    
    let request = CreatePlanRequest(
      title: title,
      penalty: penalty,
      start_time: start_time,
      location: location,
      participants: participants)
    let plan = try await PlanService.shared.createPlan(planRequest: request)
    
    await MainActor.run {
      myPlans.append(plan)
    }
  }
  
  /// fetch
  func fetchPlans(by status: [Plan.Status] = [.ongoing, .upcoming]) async {
    do {
      let plans = try await PlanService.shared.fetchPlans(by: status)
      
      await MainActor.run {
        self.myPlans = plans
      }
    } catch {
      print("error fetching plans: \(error)")
    }
  }
  
  /// read by id
  func fetchPlan(id: Int) async -> Plan? {
    do {
      let plan = try await PlanService.shared.fetchPlan(id: id)
      return plan
    } catch {
      print("error fetching plans: \(error)")
      return nil
    }
  }
  
  /// update
  func updatePlan(
    id: Int,
    title: String,
    status: Plan.Status?,
    penaltyContent: String?,
    startTime: Date,
    locationName: String,
    coordinates: CLLocationCoordinate2D,
    participants: [Int]?
  ) async throws {
    
    let isoFormatter = ISO8601DateFormatter()
    let updateRequest = PlanUpdateRequest(
      title: title,
      status: status,
      start_time: isoFormatter.string(from: startTime),
      penalty: penaltyContent.map { PenaltyCreate(content: $0) },
      location: LocationCreate(
        name: locationName,
        latitude: coordinates.latitude,
        longitude: coordinates.longitude
      ),
      participants: participants
    )
    
    let updatedPlan = try await PlanService.shared.updatePlan(id: id, updateRequest: updateRequest)
    
    // Update local cache
    if let idx = myPlans.firstIndex(where: { $0.id == updatedPlan.id }) {
      myPlans[idx] = updatedPlan
    }
    
    print("Updated Plan Successfully: \(updatedPlan)")
  }
  
  func deletePlan(id: Int) async {
    do {
      try await PlanService.shared.deletePlan(id: id)
      print("Deleted Plan Successfully: \(id)")
    } catch {
      print("error deleting plan: \(error)")
    }
  }
  
  func fetchInvites() async {
    do {
      let invites = try await PlanService.shared.fetchPlanInvites()
      
      await MainActor.run {
        self.planInvites = invites
      }
    } catch {
      print("error fetching invites: \(error)")
    }
  }
  
  func acceptInvite(inviteId: Int) async {
    do {
      let invite = try await PlanService.shared.updatePlanInvite(inviteId: inviteId, newStatus: "accepted")
      await fetchInvites()
      print("Accepted a Invite Successfully: \(invite)")
    } catch {
      print("error updating invite: \(error)")
    }
  }
  
  func declineInvite(inviteId: Int) async {
    do {
      let invite = try await PlanService.shared.updatePlanInvite(inviteId: inviteId, newStatus: "rejected")
      await fetchInvites()
      print("Declined a Invite Successfully: \(invite)")
    } catch {
      print("error updating invite: \(error)")
    }
  }
  
  func fetchCurrentUserPenaltyStatus(planId: Int) async -> Penalty.Status? {
    do {
      return try await PlanService.shared.fetchCurrentUserPenaltyStatus(planId: planId)
    } catch {
      print("error fetching current user's penalty status: \(error)")
      return nil
    }
  }
  
  func fetchAllPenaltyApprovalRequests(planId: Int) async -> [PenaltyApprovalRequestResponse] {
    do {
      return try await PlanService.shared.fetchAllPenaltyApprovalRequest(planId: planId)
    } catch {
      print("error fetching all penalty approval requests: \(error)")
      return []
    }
  }
}


// MARK: Environment Key
extension EnvironmentValues {
  var planManager: PlanManager {
    get {
      self[PlanManagerKey.self]
    } set {
      self[PlanManagerKey.self] = newValue
    }
  }
}

private struct PlanManagerKey: EnvironmentKey {
  static let defaultValue: PlanManager = PlanManager(accountManager: AccountManager())
}
