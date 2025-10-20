//
//  HomeNotificationBell.swift
//  puctee
//
//  Created by kj on 5/9/25.
//

import SwiftUI

struct HomeNotificationIcon: View {
  @Environment(\.friendManager) private var friendManager
  @Environment(\.planManager) private var planManager
  @Environment(\.colorScheme) private var colorScheme
  
  // TODO: Add logic to check if invite or unread notification are in inbox
  private var isNotificationUnread: Bool {
    !friendManager.receivedRequsts.isEmpty || !planManager.planInvites.isEmpty
  }
  
  public var body: some View {
    ZStack(alignment: .center) {
      Image(systemName: "bell")
        .resizable()
        .scaledToFit()
        .frame(height: 22)
        .fontWeight(.light)
        .foregroundStyle(colorScheme == .dark ? .white : .black)
      
      if isNotificationUnread {
        Image(systemName: "circle.fill")
          .resizable()
          .frame(width: 8, height: 8)
          .offset(x: 6, y: -6)
          .foregroundStyle(.red)
      }
    }.frame(width: 30, height: 30)
  }
}

#Preview {
  HomeNotificationIcon()
}
