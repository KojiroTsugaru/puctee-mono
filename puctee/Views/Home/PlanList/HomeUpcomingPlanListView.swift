//
//  HomePlanListView.swift
//  puctee
//
//  Created by kj on 5/9/25.
//

import SwiftUI

struct HomeUpcomingPlanListView: View {
  @Environment(\.planManager) private var planManager
  
  var body: some View {
    VStack(spacing: 20) {
      if planManager.upcomingPlans.isEmpty {
        HomePlanEmptyView(tab: .upcoming)
      } else {
        ForEach(planManager.upcomingPlans, id: \.id) { plan in
          NavigationLink(destination: PlanDetailView(plan: plan)) {
            PlanListCellView(plan: plan)
          }
        }
      }
    }
  }
}
