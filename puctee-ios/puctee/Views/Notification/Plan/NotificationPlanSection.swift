//
//  NotificationPlanSection.swift
//  puctee
//
//  Created by kj on 7/29/25.
//

import SwiftUI

struct NotificationPlanSection: View {
  @Environment(\.planManager) private var planManager
  
  var body: some View {
    ZStack(alignment: .center) {
      // Place empty-state first
      if planManager.planInvites.isEmpty {
        VStack {
          ContentUnavailableView("No notifications", systemImage: "tray.fill")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, 280)
        }
      }
      
      // Stack content on top if available
      VStack(alignment: .leading, spacing: 20) {
        Spacer()
          .frame(height: 12)
        ForEach(planManager.planInvites) { invite in
          NavigationLink(destination: PlanDetailView(plan: invite.plan)) {
            PlanInviteListCell(invite: invite)
          }
        }
      }
    }
  }
}
