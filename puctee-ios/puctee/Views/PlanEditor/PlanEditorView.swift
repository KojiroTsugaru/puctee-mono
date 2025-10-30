//
//  PlanEditorView.swift
//  puctee
//
//  Created by kj on 5/10/25.
//

import SwiftUI
import CoreLocation

struct PlanEditorView: View {
  let plan: Plan?
  var onCreate: () -> Void = {}
  
  @State private var showDatePicker: Bool = false
  @State private var showCoordinatePicker: Bool = false
  @State private var showCelebrateModal: Bool = false
  
  @State private var vm: PlanEditorViewModel = .init()
  @Environment(\.planManager) var planManager
  @Environment(\.accountManager) var accountManager
  
  init(plan: Plan? = nil, onCreate: @escaping () -> Void = {}) {
    self.plan = plan
    _vm = State(initialValue: PlanEditorViewModel(plan: plan))
    self.onCreate = onCreate
  }
  
  var body: some View {
    NavigationStack {
      PlanEditorHeaderView(onCreate: onCreate, vm: $vm)
        .padding(.horizontal)
      if let err = vm.serverError {
        Text(err)
          .font(.caption)
          .foregroundColor(.red)
      }
      ScrollView(showsIndicators: false) {
        VStack(alignment: .leading, spacing: 24) {
          PlanEditorTitleTextfield(vm: $vm)
          PlanEditorPenaltySection(vm: vm)
          PlanEditorDateSection(vm: $vm)
          PlanEditorTimeSection(vm: $vm)
          PlanEditorLocationSection(vm: $vm, showCoordinatePicker: $showCoordinatePicker)
          PlanEditorParticipantsSection(vm: vm)
        }
        .padding(.horizontal)
      }
      .background(Color(.systemBackground).ignoresSafeArea())
      .navigationBarHidden(true)
      .navigationDestination(isPresented: $showCoordinatePicker) {
        PlanEditorLocationPicker(coordinates: $vm.selectedCoordinates)
      }
    }
    .overlay {
      if vm.isLoading {
        ProgressView(plan == nil ? "Creating plan..." : "Saving plan...")
          .padding()
          .background(.regularMaterial)
          .cornerRadius(12)
      }
    }
    .task {
      if let currentUser = accountManager.currentUser,
        !vm.participants.contains(where: { $0.id == currentUser.id }) {
        vm.participants.append(currentUser)
      }
    }
  }
}

// MARK: - Preview
struct PlanEditorView_Previews: PreviewProvider {
  static var previews: some View {
    PlanEditorView(plan: nil)
  }
}
