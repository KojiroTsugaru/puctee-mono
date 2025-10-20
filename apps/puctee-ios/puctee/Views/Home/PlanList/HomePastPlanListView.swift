//
//  HomePastPlanListView.swift
//  puctee
//
//  Created by kj on 8/5/25.
//

import SwiftUI

struct HomePastPlanListView: View {
  @Environment(\.planManager) private var planManager
  
  var body: some View {
    VStack(spacing: 0) {
      if planManager.pastPlans.isEmpty && planManager.ongoingPlans.isEmpty {
        HomePlanEmptyView(tab: .past)
      } else {
        // plans with pending penalty
        if !planManager.ongoingPlans.isEmpty {
          HStack {
            Text("Pending Penalties")
              .font(.title3)
              .fontWeight(.bold)
            Spacer()
          }
          .padding(.bottom, 6)
          .padding(.horizontal)
          
          VStack(spacing: 20) {
            ForEach(planManager.ongoingPlans, id: \.id) { plan in
              NavigationLink(destination: PlanDetailView(plan: plan)) {
                PlanListCellView(plan: plan)
              }
            }
          }
          .padding(.bottom)
        }
        
        // past plans
        HStack {
          Text("Completed & Cancelled Plans")
            .font(.title3)
            .fontWeight(.bold)
          Spacer()
        }
        .padding(.bottom, 6)
        .padding(.horizontal)
        
        VStack(spacing: 20) {
          ForEach(planManager.pastPlans, id: \.id) { plan in
            NavigationLink(destination: PlanDetailView(plan: plan)) {
              PlanListCellView(plan: plan)
            }
          }
        }
      }
    }
  }
}
