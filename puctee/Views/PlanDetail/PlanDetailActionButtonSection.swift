//
//  PlanDetailActionButtonSection.swift
//  puctee
//
//  Created by kj on 8/28/25.
//

import SwiftUI

struct PlanDetailActionButtonSection: View {
  @Binding var showPenaltyApprovalSheet: Bool
  let penaltyStatus: Penalty.Status
  
  var body: some View {
    VStack {
      Text(buttonHelperText)
        .font(.caption)
        .foregroundStyle(.secondary)
      
      Button {
        showPenaltyApprovalSheet.toggle()
      } label: {
        Label(buttonText, systemImage: "checkmark.seal.fill")
          .font(.subheadline.bold())
          .frame(maxWidth: .infinity)
          .padding(.vertical, 12)
          .background(Color(.systemRed).gradient)
          .foregroundColor(.white)
          .clipShape(Capsule())
      }
      .buttonStyle(PlainButtonStyle())
      .shadow(color: Color.accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
      .disabled(!isPenaltyRequired)
    }
    .padding()
  }
  
  private var isPenaltyRequired: Bool {
    penaltyStatus == .required
  }
  
  private var buttonText: String {
    switch penaltyStatus {
      case .required:
        "I Completed Penalty"
      case .pendingApproval:
        "Wating for an Approval"
      default:
        ""
    }
  }
  
  private var buttonHelperText: String {
    switch penaltyStatus {
      case .required:
        "press the button below to ask for approval"
      case .pendingApproval:
        "you have already sent an approval reqeust"
      default:
        ""
    }
  }
}
