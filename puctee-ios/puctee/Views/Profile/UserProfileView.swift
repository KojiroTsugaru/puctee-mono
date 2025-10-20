//
//  UserProfileView.swift
//  puctee
//
//  Created by kj on 6/8/25.
//

import SwiftUI
import Kingfisher

// MARK: - View
struct UserProfileView: View {
  let userProfileType: UserProfileType
  @Environment(\.friendManager) private var friendManager: FriendManager
  @Environment(\.accountManager) private var accountManager: AccountManager
  
  var body: some View {
    // Instantiate inner view once environment values are available
    _UserProfileView(
      vm: UserProfileViewModel(
        userProfileType: userProfileType,
        friendManager: friendManager,
        accountManager: accountManager
      )
    )
  }
}

// MARK: - Inner View for StateObject
fileprivate struct _UserProfileView: View {
  @StateObject var vm: UserProfileViewModel
  
  var body: some View {
    VStack(spacing: 24) {
      // Avatar
      KFImage(vm.profileUser.profileImageUrl)
        .placeholder {
          PlaceholderInitial()
            .frame(width: 100, height: 100)
        }
        .resizable()
        .scaledToFill()
        .frame(width: 100, height: 100)
        .clipShape(Circle())
        .overlay(Circle().stroke(.secondary, lineWidth: 1))
      
      // Display name
      Text(vm.profileUser.displayName)
        .font(.title3)
        .fontWeight(.semibold)
      
      // Actions
      HStack(spacing: 12) {
        switch vm.userProfileType {
          case .me:
            NavigationLink {
              UserProfileFriendListView()
            } label: {
              Label("\(vm.friendCount) Friends", systemImage: "person.2.fill")
            }
            .buttonStyle(.bordered)
            
          case .other:
            if vm.isFriend {
              Button {
                vm.removeFriend()
              } label: {
                Label("Unfriend", systemImage: "person.crop.circle.badge.minus")
              }
              .buttonStyle(.bordered)
              .tint(.red)
              
            } else if vm.isInvited {
              Button {
                // no-op
              } label: {
                Label("Requested", systemImage: "hourglass")
              }
              .buttonStyle(.borderedProminent)
              .disabled(true)
              
            } else {
              Button {
                vm.sendFriendRequest()
              } label: {
                Label("Send Friend Request", systemImage: "person.crop.circle.badge.plus")
              }
              .buttonStyle(.borderedProminent)
            }
        }
      }
      
      // Trust stats
      UserProfileTrustStatsView(user: vm.profileUser)
        .id(vm.profileUser.id)
      
      Spacer()
    }
    .padding()
    .alert(
      "Invitation already accepted",
      isPresented: $vm.showAlert
    ) {
      Button("OK", role: .cancel) { }
    } message: {
      Text("""
    The invitation from this user has already been accepted.
    Please check your notification box.
    """)
    }
    .task {
      await vm.loadState()
    }
  }
}

