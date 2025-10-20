//
//  HomeHeader.swift
//  puctee
//
//  Created by kj on 5/13/25.
//

import SwiftUI
import Kingfisher

struct HomeHeader: View {
  @Environment(\.accountManager) private var accountManager
  @Environment(\.planManager) private var planManager
  @Environment(\.friendManager) private var friendManager
  @Binding var showSidebar: Bool
  
  var body: some View {
    HStack {
      KFImage(accountManager.currentUser?.profileImageUrl)
        .placeholder {
          PlaceholderInitial()
            .frame(width: 30, height: 30)
        }
        .resizable()
        .scaledToFill()
        .frame(width: 30, height: 30)
        .clipShape(Circle())
        .overlay(Circle().stroke(.gray, lineWidth: 1))
        .onTapGesture {
          withAnimation(.easeInOut) {
            showSidebar.toggle()
          }
        }
      
      Text("Home")
        .font(.title3)
        .fontWeight(.semibold)
        .padding(.horizontal, 4)
      Spacer()

      NavigationLink {
        NotificationListView()
      } label: {
        HomeNotificationIcon()
          .padding(.trailing)
      }
    }
    .padding(.horizontal)
  }
}
