//
//  HomePlanEmptyView.swift
//  puctee
//
//  Created by kj on 6/8/25.
//

import SwiftUI

struct HomePlanEmptyView: View {
  let tab: HomePlanListTabView.ListTab
  private var tabName: String {
    switch tab {
      case .upcoming:
        return "Upcoming"
      case .past:
        return "Past"
    }
  }
  
  var body: some View {
    VStack(spacing: 24) {
      Spacer()
      
      // Icon
      Image("plan_icon")
        .resizable()
        .scaledToFit()
        .frame(width: 100, height: 100)
        .foregroundColor(.secondary.opacity(0.7))
      
      // Main message
      Text("You have no \(tabName.lowercased()) plans")
        .font(.title3)
        .fontWeight(.semibold)
      
      // Sub message
      Text("Let's create a new plan from the + button")
        .multilineTextAlignment(.center)
        .font(.subheadline)
        .foregroundColor(.secondary)
      
      Spacer()
    }
    .padding(32)
  }
}

struct HomePlanEmptyView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      HomePlanEmptyView(tab: .upcoming)
        .preferredColorScheme(.light)
      HomePlanEmptyView(tab: .past)
        .preferredColorScheme(.dark)
    }
    .previewLayout(.sizeThatFits)
  }
}
