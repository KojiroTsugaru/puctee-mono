//
//  UserProfileFriendListView.swift
//  puctee
//
//  Created by kj on 7/4/25.
//

import SwiftUI

struct UserProfileFriendListView: View {
  @Environment(\.friendManager) private var friendManager
  
  var body: some View {
    VStack {
      ScrollView(.vertical) {
        ForEach(friendManager.friends) { user in
          UserProfileFriendListCell(user: user)
            .contentShape(Rectangle())
          Divider()
        }
      }
      .padding(.vertical, 4)
      .frame(maxWidth: .infinity)
      
      Spacer()
    }
    .listStyle(.plain)
    .navigationTitle("Friends")
    .navigationBarTitleDisplayMode(.inline)
    .overlay {
      if friendManager.friends.isEmpty {
        EmptyFriendsView()
      }
    }
  }
}

#Preview {
  UserProfileFriendListView()
}
