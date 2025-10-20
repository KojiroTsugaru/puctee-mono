//
//  FriendManager.swift
//  puctee
//
//  Created by kj on 6/8/25.
//

import Observation
import SwiftUI

@Observable class FriendManager {
  var friends: [User] = []
  var sentRequests: [FriendInvite] = []
  var receivedRequsts: [FriendInvite] = []
  
  func fetchFriends() async {
    do {
      friends = try await FriendService.shared.fetchFriends()
    } catch {
      print("FetchFriends error: \(error)")
      friends = []
    }
  }
  
  func sendFriendInvite(to user: User) async throws {
    let _ = try await FriendService.shared.sendInvite(to: user.id)
  }
  
  func fetchSentInvites() async {
    do {
      sentRequests = try await FriendService.shared.fetchSentInvites()
    } catch {
      print("FetchSentFriendRequest error: \(error)")
      sentRequests = []
    }
  }
  
  func fetchReceivedInvites() async {
    do {
      receivedRequsts = try await FriendService.shared.fetchReceivedInvites()
    } catch {
      print("fetchReceivedInvites error: \(error)")
      receivedRequsts = []
    }
  }
  
  func acceptFriendInvite(_ invite: FriendInvite) async {
    do {
      try await FriendService.shared.acceptInvite(inviteId: invite.id)
      await self.fetchReceivedInvites()
    } catch {
      print("acceptFriendInvite error: \(error)")
    }
  }
  
  func declineFriendInvite(_ invite: FriendInvite) async {
    do {
      try await FriendService.shared.declineInvite(inviteId: invite.id)
      await self.fetchReceivedInvites()
    } catch {
      print("declineFriendInvite error: \(error)")
    }
  }
  
  func removeFriend(_ user: User) async {
    do {
      try await FriendService.shared.removeFriend(friendId: user.id)
    } catch {
      print("removeFriend error: \(error)")
    }
  }
  
  func isUserFriend(_ user: User) -> Bool {
    return friends.contains(where: { $0.id == user.id })
  }
  
  func isUserInvited(_ user: User) -> Bool {
    return sentRequests.contains(where: { $0.receiverId == user.id })
  }
}

// MARK: Environment Key
extension EnvironmentValues {
  var friendManager: FriendManager {
    get {
      self[FriendManagerKey.self]
    } set {
      self[FriendManagerKey.self] = newValue
    }
  }
}

private struct FriendManagerKey: EnvironmentKey {
  static let defaultValue: FriendManager = FriendManager()
}

