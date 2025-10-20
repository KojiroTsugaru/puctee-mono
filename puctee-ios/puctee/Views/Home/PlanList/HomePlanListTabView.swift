//
//  PlanListTabView.swift
//  puctee
//
//  Created by kj on 8/5/25.
//

import SwiftUI

struct HomePlanListTabView: View {
  // MARK: – Tabs
  enum ListTab: String, CaseIterable, Identifiable {
    case upcoming = "Upcoming"
    case past     = "Past"
    var id: Self { self }
  }
  
  @State private var selectedTab: ListTab = .upcoming
  
  private var showPastDot: Bool {
    return !planManager.ongoingPlans.isEmpty
  }
  
  @Environment(\.planManager) private var planManager
  
  // Helper to get the index of the selected tab
  private var selectedIndex: Int {
    ListTab.allCases.firstIndex(of: selectedTab) ?? 0
  }
  
  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Text("My Schedule")
          .font(.title2)
          .fontWeight(.bold)
        Spacer()
      }
      .padding(.horizontal)
      .padding(.bottom, 4)
      
      ZStack(alignment: .leading) {
        // Track
        Capsule()
          .fill(Color(UIColor.systemGray5))
        
        // Thumb
        GeometryReader { geo in
          let segmentWidth = geo.size.width / CGFloat(ListTab.allCases.count)
          Capsule()
            .fill(Color.accentColor)
            .frame(width: segmentWidth, height: geo.size.height)
            .offset(x: CGFloat(selectedIndex) * segmentWidth)
            .animation(.easeInOut(duration: 0.20), value: selectedTab)
        }
        
        // Buttons + Dot
        HStack(spacing: 0) {
          ForEach(ListTab.allCases) { tab in
            ZStack {
              Text(tab.rawValue)
                .font(.system(size: 14, weight: .medium))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .foregroundColor(selectedTab == tab ? .white : .primary.opacity(0.7))
              
              // red dot on “Past”
              if showPastDot && tab == .past && selectedTab != .past {
                Circle()
                  .fill(Color.red)
                  .frame(width: 10, height: 10)
                  .offset(x: 24, y: -8)
              }
            }
            .frame(maxWidth: .infinity, minHeight: 36)
            .contentShape(Rectangle())
            .onTapGesture {
              selectedTab = tab
            }
          }
        }
      }
      .frame(height: 36)
      .padding(.horizontal)
      .padding(.top, 8)
      
      ScrollView {
        VStack(alignment: .leading, spacing: 12) {
          switch selectedTab {
            case .upcoming:
              HomeUpcomingPlanListView()
            case .past:
              HomePastPlanListView()
          }
        }
        .padding(.vertical)
      }
    }
  }
}

struct ListByTabView_Previews: PreviewProvider {
  static var previews: some View {
    HomePlanListTabView()
  }
}
