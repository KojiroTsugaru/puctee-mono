//
//  PlanDetailPenaltyCard.swift
//  puctee
//
//  Created by kj on 5/22/25.
//

import SwiftUI

struct PlanDetailPenaltySection: View {
  @Environment(\.planManager) private var planManager
  
  let plan: Plan?
  @Binding var penaltyStatus: Penalty.Status?
  @State private var penaltyApprovalRequests: [PenaltyApprovalRequestResponse] = []
  @State private var selectedRequest: PenaltyApprovalRequestResponse?
  
  var body: some View {
    VStack(alignment: .leading) {
      // title
      HStack {
        Label("Penalty", systemImage: "tag.fill")
        
        if penaltyStatus == .required {
          Text("Action Required")
            .font(.caption)
            .foregroundStyle(.red)
            .padding(.leading, 4)
        }
        Spacer()
      }
      .padding(.bottom, 4)
      
      // penalties capsule
      if let pens = plan?.penalties {
        ForEach(pens) { pen in
          Text(pen.content)
            .font(.subheadline)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
              Capsule()
                .fill(Color(penaltyStatus == .required ? .systemRed : .accent).opacity(0.1))
            )
        }
      } else {
        ProgressView("Loading...")
          .font(.subheadline)
      }
      
      // approval requests
      ForEach(penaltyApprovalRequests) { req in
        ApprovalRequestRow(request: req) {
          selectedRequest = req
        }
      }
    }
    .task {
      // load penalty approval requests for a plan
      if let id = plan?.id {
        self.penaltyApprovalRequests = await planManager.fetchAllPenaltyApprovalRequests(planId: id)
      }
    }
    .sheet(item: $selectedRequest) { req in
      PlanPenaltyApprovalView(approvalRequestId: req.id)
        .presentationDetents([.medium, .large])
    }
  }
}

#Preview {
  VStack {
    PlanDetailPenaltySection(plan: SampleData.planPicnic, penaltyStatus: Binding.constant(.required))
      .padding()
  }
}
