//
//  PlanInviteListCell.swift
//  puctee
//
//  Created by kj on 5/17/25.
//

import SwiftUI

struct PlanInviteListCell: View {
  let invite: PlanInvite
  @Environment(\.planManager) private var planManager
  @State private var showConfirmation: Bool = false
  @State private var confirmationMessage = ""
  
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      header
      dateInfo
      locationAndParticipants
      actionButtons
    }
    .padding()
    .background(.regularMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
    .padding(.horizontal)
    .alert(confirmationMessage, isPresented: $showConfirmation) {
      Button("OK", role: .cancel) {
        confirmationMessage = ""
      }
    }
  }
  
  private var header: some View {
    HStack {
      Text(invite.plan.title)
        .font(.headline)
        .foregroundColor(.primary)
      Spacer()
      Image(systemName: "chevron.right")
        .font(.caption)
        .foregroundColor(.secondary)
    }
  }
  
  private var dateInfo: some View {
    Text(formattedDateText(from: invite.plan.startTime))
      .font(.subheadline)
      .foregroundColor(.secondary)
  }
  
  private var locationAndParticipants: some View {
    HStack(spacing: 8) {
      Label(invite.plan.location.name, systemImage: "mappin.and.ellipse")
        .font(.subheadline)
        .foregroundColor(.secondary)
      Spacer()
      ParticipantsStackView(for: invite.plan.participants)
    }
  }
  
  private var actionButtons: some View {
    HStack(spacing: 12) {
      // Decline Button
      Button {
        Task {
          await planManager.declineInvite(inviteId: invite.id)
          showConfirmation.toggle()
          confirmationMessage = "Declined plan: \(invite.plan.title)"
        }
      } label: {
        Label("Decline", systemImage: "xmark")
          .font(.subheadline.bold())
          .frame(maxWidth: .infinity)
          .padding(.vertical, 12)
          .background(.ultraThinMaterial)
          .foregroundColor(.primary)
          .clipShape(Capsule())
      }
      .buttonStyle(PlainButtonStyle())
      .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
      
      // Accept Button
      Button {
        Task {
          await planManager.acceptInvite(inviteId: invite.id)
          showConfirmation.toggle()
          confirmationMessage = "Accepted plan: \(invite.plan.title)"
        }
      } label: {
        Label("Accept", systemImage: "checkmark")
          .font(.subheadline.bold())
          .frame(maxWidth: .infinity)
          .padding(.vertical, 12)
          .background(Color.accentColor.gradient)
          .foregroundColor(.white)
          .clipShape(Capsule())
      }
      .buttonStyle(PlainButtonStyle())
      .shadow(color: Color.accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
    }
    .padding(.top, 12)
  }
}

#Preview {
  NavigationStack {
    PlanInviteListCell(invite: SampleData.mockPlanInvite)
  }
}

