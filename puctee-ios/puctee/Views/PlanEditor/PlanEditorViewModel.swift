//
//  PlanEditorViewModel.swift
//  puctee
//
//  Created by kj on 5/15/25.
//

import Observation
import SwiftUI
import PhotosUI

@Observable class PlanEditorViewModel {
  // ID to hold when editing an existing plan
  let planId: Int?
  
  // Input fields
  var titleText: String
  var startTime: Date
  var locationNameText: String
  var selectedCoordinates: CLLocationCoordinate2D?
  var penaltyText: String
  var participants: [User]
  var isLoading: Bool = false
  
  // Errors
  var titleError: String?
  var dateError: String?
  var locationError: String?
  var participantsError: String?
  var serverError: String?
  
  // flag for creating a plan
  var didCreate: Bool = false
  
  /// Receives `plan` at initialization. If nil, it's new creation mode.
  init(plan: Plan? = nil) {
    if let plan = plan {
      self.planId = plan.id
      self.titleText = plan.title
      self.startTime = plan.startTime
      self.locationNameText = plan.location.name
      self.selectedCoordinates = CLLocationCoordinate2D(
        latitude: plan.location.latitude,
        longitude: plan.location.longitude
      )
      self.penaltyText = plan.penalties?.first?.content ?? ""
      self.participants = plan.participants
    } else {
      self.planId = nil
      self.titleText = ""
      self.startTime = Date()
      self.locationNameText = ""
      self.selectedCoordinates = nil
      self.penaltyText = ""
      self.participants = []
    }
  }
  
  /// New creation
  func createPlan(
    using planManager: PlanManager,
    onCreate: @escaping @MainActor () -> Void
  ) async {
    
    guard validatePlanCreateInput() else { return }
    guard planId == nil else { return }
    
    isLoading = true
    defer { isLoading = false }
    
    let participantsIds = participants.map { $0.id }
    
    do {
      try await planManager.createPlan(
        title: titleText,
        penaltyContent: penaltyText.isEmpty ? nil : penaltyText,
        start_time: startTime,
        locationName: locationNameText,
        coordinates: selectedCoordinates!,
        participants: participantsIds
      )
      await onCreate()
    } catch {
      print("Error creating plan: \(error)")
      serverError = "Network error: Could not create plan. Try again later."
    }
  }
  
  /// Update
  func savePlan(
    using planManager: PlanManager,
    onSave: @escaping @MainActor () -> Void
  ) async {
    guard validatePlanCreateInput() else { return }
    guard planId != nil else { return }
    
    isLoading = true
    defer { isLoading = false }
    
    let participantsIds = participants.map { $0.id }
    
    do {
      try await planManager.updatePlan(
        id: planId!,
        title: titleText,
        status: nil,
        penaltyContent: penaltyText,
        startTime: startTime,
        locationName: locationNameText,
        coordinates: selectedCoordinates!,
        participants: participantsIds
      )
      await onSave()
    } catch {
      print("Error creating plan: \(error)")
      serverError = "Network error: Could not create plan. Try again later."
    }
  }
  
  func validatePlanCreateInput() -> Bool {
    // Clear previous errors
    titleError = nil
    dateError = nil
    locationError = nil
    participantsError = nil
    serverError = nil
    
    var isValid = true
    
    // Title required check
    if titleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      titleError = "Please enter a title"
      isValid = false
    }
    
    // Start time must be after current time
    if startTime < Date() {
      dateError = "Time must be set after the current time"
      isValid = false
    }
    
    // Both location name and coordinates are required
    if locationNameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedCoordinates == nil {
      locationError = "Please set a location"
      isValid = false
    }
    
    return isValid
  }

}

