//
//  NotificationFriendSection.swift
//  puctee
//
//  Created by kj on 7/29/25.
//

import SwiftUI

struct NotificationFriendSection: View {
  @Environment(\.friendManager) private var friendManager
  
  var body: some View {
    if friendManager.receivedRequsts.isEmpty {
      VStack {
        ContentUnavailableView("No friend invitations", systemImage: "person.2.fill")
          .padding(.top, 280)
      }
    } else {
      VStack(alignment: .leading) {
        ForEach(friendManager.receivedRequsts) { invite in
          FriendInviteListCell(invite: invite)
          Divider()
        }
      }
      .padding(.top)
    }
  }
}
