//
//  NotificationListView.swift
//  puctee
//
//  Created by kj on 5/17/25.
//

import SwiftUI

/// Types of notification tabs
private enum NotificationTab: String, CaseIterable, Identifiable {
  case plan   = "Plans"    // Plan invitations
  case friend = "Friends"  // Friend invitations
  
  var id: Self { self }
}

struct NotificationListView: View {
  @Environment(\.planManager) private var planManager
  @Environment(\.friendManager) private var friendManager
  
  @State private var selectedTab: NotificationTab = .plan
  
  var body: some View {
    VStack(spacing: 0) {
      // Segmented Picker for tab switching
      Picker("", selection: $selectedTab) {
        ForEach(NotificationTab.allCases) { tab in
          Text(tab.rawValue).tag(tab)
        }
      }
      .pickerStyle(SegmentedPickerStyle())
      .padding(.horizontal)
      .padding(.top, 8)
      
      
      // Display content of the selected tab
      ScrollView {
        switch selectedTab {
          case .plan:
            NotificationPlanSection()
          case .friend:
            NotificationFriendSection()
        }
      }
      
    }
    .navigationTitle("Notifications")
    .navigationBarTitleDisplayMode(.inline)
  }
}

