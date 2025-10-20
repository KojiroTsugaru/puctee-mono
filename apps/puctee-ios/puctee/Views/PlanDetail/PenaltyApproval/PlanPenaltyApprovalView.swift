//
//  PlanPenaltyApprovalView.swift
//  puctee
//
//  Created by kj on 8/24/25.
//

import SwiftUI
import Kingfisher

struct PlanPenaltyApprovalView: View {
  let approvalRequestId: Int
  @Environment(\.dismiss) private var dismiss
  
  @State private var request: PenaltyApprovalRequestResponse?
  @State private var penaltyUser: User?
  @State private var isProcessing = false
  @State private var showResultAlert = false
  @State private var resultMessage = ""
  @State private var showErrorAlert = false
  @State private var errorMessage: String = ""
  
  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      HStack {
        Button { dismiss() } label: {
          Image(systemName: "xmark")
            .font(.system(size: 28))
            .foregroundStyle(.gray)
        }
        Spacer()
      }
      
      // Title
      VStack(alignment: .leading, spacing: 8) {
        HStack(spacing: 8) {
          Image(systemName: "tag.fill")
          Text("Penalty Approval")
        }
        .font(.system(size: 16, weight: .semibold))
        
        Text(request?.penaltyName ?? "...")
          .font(.system(size: 22, weight: .bold))
          .fixedSize(horizontal: false, vertical: true)
      }
      .padding(.top, 6)
      
      // Requester
      HStack(spacing: 8) {
        Image(systemName: "person.crop.circle.fill")
          .font(.system(size: 20))
          .foregroundStyle(.secondary)
        Text(penaltyUser?.displayName ?? "User #\(String(describing: penaltyUser?.id))")
          .font(.subheadline.weight(.semibold))
        Spacer()
        Text(request?.createdAt.description ?? "Unknown date")
      }
      
      // Proof (submitted)
      KFImage(request?.proofImageUrl)
        .placeholder {
          Text("Failed to load proof")
            .foregroundStyle(.secondary)
            .frame(width: 360, height: 360)
            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
        }
        .resizable()
        .scaledToFill()
        .frame(height: 360)
        .frame(width: 360)
        .clipped()
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
      
      // Requester comment
      if let rc = request?.comment, !rc.isEmpty {
        LabeledBubble(title: "Comment", text: rc)
      }
      
      Spacer()
      
      // Actions
      VStack(spacing: 12) {
        Button {
          Task { await respond(approve: true) }
        } label: {
          Label("Approve", systemImage: "checkmark.circle.fill")
            .font(.system(size: 16, weight: .bold))
        }
        .buttonStyle(CapsuleFillButtonStyle(.green))
        .disabled(isProcessing)
        .opacity(isProcessing ? 0.6 : 1)
        
        Button {
          Task { await respond(approve: false) }
        } label: {
          Label("Decline", systemImage: "xmark.octagon.fill")
            .font(.system(size: 16, weight: .bold))
        }
        .buttonStyle(CapsuleFillButtonStyle(.red))
        .disabled(isProcessing)
        .opacity(isProcessing ? 0.6 : 1)
        
        Button("Cancel") { dismiss() }
          .font(.system(size: 16))
          .foregroundColor(.primary)
          .padding(.top, 4)
      }
    }
    .padding(20)
    .alert(resultMessage, isPresented: $showResultAlert) {
      Button("OK", role: .cancel) { dismiss() }
    }
    .alert(errorMessage, isPresented: $showErrorAlert) {
      Button("Close", role: .cancel) { }
    }
    .task {
      await configure()
    }
    .background(Color.white)
  }
  
  // MARK: - Actions
  
  private func configure() async {
    do {
      self.request = try await PlanService.shared.fetchPenaltyApprovalRequest(requestId: approvalRequestId)
      
      if let penaltyUserId = request?.penaltyUserId {
        self.penaltyUser = try await UserService.shared.fetchUser(id: penaltyUserId)
      }
      self.errorMessage = ""
    } catch {
      self.errorMessage = "Network Error occurred. Please try again later."
      self.showErrorAlert.toggle()
    }
  }
  
  private func respond(approve: Bool) async {
    guard let planId = request?.planId else { return }
    isProcessing = true
    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
    
    // TODO: Request Approval/Decline action
    do {
      if approve {
        try await PlanService.shared.approvePenaltyRequest(planId: planId, requestId: approvalRequestId)
      } else {
        try await PlanService.shared.declinePenaltyRequest(planId: planId, requestId: approvalRequestId)
      }
      resultMessage = approve ? "You have approved a penalty" : "You have declined a penalty"
      UINotificationFeedbackGenerator().notificationOccurred(.success)
      showResultAlert = true
      isProcessing = false
    } catch {
      self.errorMessage = "Network Error occurred. Please try again later."
      self.showErrorAlert.toggle()
      isProcessing = false
    }
  }
}

// MARK: - Subviews

/// 申請者コメントを吹き出しで表示
private struct LabeledBubble: View {
  let title: String
  let text: String
  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title)
        .font(.caption.weight(.semibold))
        .foregroundStyle(.secondary)
      Text(text)
        .font(.subheadline)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
          RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color(.secondarySystemBackground))
        )
    }
  }
}

#Preview {
  PlanPenaltyApprovalView(approvalRequestId: 1)
}
