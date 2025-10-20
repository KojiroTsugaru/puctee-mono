//
//  PenaltyApprovalModal.swift
//  puctee
//
//  Created by kj on 8/26/25.
//

import SwiftUI

struct PenaltyApprovalModal: View {
  let approvalRequestId: Int
  @Binding var isPresented: Bool
  
  var body: some View {
    ZStack {
      Text("PenaltyApprovalModal")
    }
      .sheet(isPresented: $isPresented) {
        PlanPenaltyApprovalView(
          approvalRequestId: approvalRequestId
        )
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(true)
      }
  }
}
