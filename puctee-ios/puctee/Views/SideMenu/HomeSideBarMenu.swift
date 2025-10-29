//
//  SidebarMenu.swift
//  puctee
//
//  Created by kj on 5/14/25.
//

import SwiftUI
import Kingfisher
import PhotosUI

@MainActor
struct HomeSideBarMenu: View {
  @Environment(\.accountManager) private var accountManager
  @Environment(\.colorScheme) private var colorScheme
  
  @State private var isShowingPhotoPicker = false
  
  var body: some View {
    VStack(alignment: .leading, spacing: 30) {
      // Tappable avatar to open photo picker
      HStack {
        Button {
          isShowingPhotoPicker = true
        } label: {
          KFImage(accountManager.currentUser?.profileImageUrl)
            .placeholder {
              PlaceholderInitial()
                .frame(width: 60, height: 60)
            }
            .resizable()
            .scaledToFill()
            .frame(width: 60, height: 60)
            .clipShape(Circle())
            .overlay(Circle().stroke(.gray, lineWidth: 1))
        }
        
        VStack(alignment: .leading) {
          Text(accountManager.currentUser?.displayName ?? "no name")
            .font(.headline)
          Text("@\(accountManager.currentUser?.username ?? "no user")")
            .font(.subheadline)
        }
      }
      
      Divider()
      
      // Menu items
      Group {
        NavigationLink {
          FriendSearchView()
        } label: {
          Label("Find Users", systemImage: "magnifyingglass")
        }
        
        NavigationLink {
          UserProfileView(userProfileType: .me)
        } label: {
          Label("My Page", systemImage: "person")
        }
        
        NavigationLink {
          SettingView()
        } label: {
          Label("Settings", systemImage: "gear")
        }
        
        Spacer()
      }
      .padding(.horizontal)
    }
    .padding(.top, 50)
    .padding(.horizontal, 20)
    .sheet(isPresented: $isShowingPhotoPicker) {
      HomeSideBarProfileIconPicker(isShowingPhotoPicker: $isShowingPhotoPicker)
    }
  }
}
