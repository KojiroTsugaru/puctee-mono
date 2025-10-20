//
//  UserProfileViewMode.swift
//  puctee
//
//  Created by kj on 7/29/25.
//

import SwiftUI
import Kingfisher

enum UserProfileType {
  case me
  case other(user: User)
}

// MARK: - ViewModel
@MainActor
final class UserProfileViewModel: ObservableObject {
  // Published properties drive the UI
  @Published var profileUser: User
  @Published var isFriend: Bool = false
  @Published var isInvited: Bool = false
  @Published var friendCount: Int = 0
  @Published var showAlert = false
  
  let userProfileType: UserProfileType
  private let friendManager: FriendManager
  private let accountManager: AccountManager
  
  init(
    userProfileType: UserProfileType,
    friendManager: FriendManager,
    accountManager: AccountManager
  ) {
    self.userProfileType = userProfileType
    self.friendManager = friendManager
    self.accountManager = accountManager
    
    // Determine which user to show
    switch userProfileType {
      case .me:
        guard let me = accountManager.currentUser else {
          fatalError("No current user available")
        }
        self.profileUser = me
      case .other(let user):
        self.profileUser = user
    }
    
    // Initial state load
    Task { await loadState() }
  }
  
  /// Fetch friends/invites then update flags
  func loadState() async {
    await friendManager.fetchFriends()
    await friendManager.fetchSentInvites()
    updateFriendFlags()
  }
  
  private func updateFriendFlags() {
    isFriend = friendManager.isUserFriend(profileUser)
    isInvited = friendManager.isUserInvited(profileUser)
    friendCount = friendManager.friends.count
  }
  
  /// Trigger a friend request
  func sendFriendRequest() {
    Task {
      do {
        _ = try await friendManager.sendFriendInvite(to: profileUser)
        await loadState()
      } catch FriendServiceError.inviteAlreadyExist(statusCode: 400) {
        showAlert = true
      } catch {
        print("error sending friend request:", error)
      }
    }
  }
  
  /// remove friend
  func removeFriend() {
    Task {
      _ = await friendManager.removeFriend(profileUser)
      await loadState()
    }
  }
}
