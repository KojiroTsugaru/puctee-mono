//
//  FriendSearchListCell.swift
//  puctee
//
//  Created by kj on 6/8/25.
//

import SwiftUI
import Kingfisher

struct UserProfileFriendListCell: View {
  let user: User
  
  var body: some View {
    NavigationLink {
      UserProfileView(userProfileType: .other(user: user))
    } label: {
      HStack(spacing: 12) {
        KFImage(user.profileImageUrl)
          .placeholder {
            PlaceholderInitial()
              .frame(width: 40, height: 40)
          }
          .resizable()
          .scaledToFill()
          .frame(width: 40, height: 40)
          .clipped()
          .clipShape(Circle())
          .overlay(Circle().stroke(Color(.systemGray4), lineWidth: 1))
        
        VStack(alignment: .leading, spacing: 2) {
          Text(user.displayName)
            .font(.body)
          Text("@\(user.username)")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        Spacer()
        
        Image(systemName: "chevron.forward")
          .foregroundStyle(.secondary)
          .padding(.horizontal)
      }
      .padding(.vertical, 4)
      .padding(.horizontal)
      .foregroundStyle(.primary)
    }
  }
}
