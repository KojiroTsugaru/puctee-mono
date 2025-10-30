//
//  FriendInviteListCell.swift
//  puctee
//
//  Created by kj on 7/29/25.
//

import SwiftUI
import Kingfisher

struct FriendInviteListCell: View {
  let invite: FriendInvite
  
  @State private var sender: User? = nil
  @Environment(\.accountManager) private var accountManager
  @Environment(\.friendManager) private var friendManager
  
  var body: some View {
    Group {
      if let user = sender {
        // sender が取れたら通常セル
        NavigationLink(destination: UserProfileView(userProfileType: .other(user: user))) {
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
            
            HStack(spacing: 12) {
              // Accept Button (uses your app’s accentColor)
              Button {
                Task { await friendManager.acceptFriendInvite(invite) }
              } label: {
                Text("Accept")
                  .font(.body.bold())
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 12)
                  .background(Color.accentColor.opacity(0.2))
                  .foregroundColor(Color.accentColor)
                  .clipShape(Capsule())
              }
              .buttonStyle(PlainButtonStyle())
              .shadow(color: .black.opacity(0.02), radius: 2, x: 0, y: 1)
                
              // Decline Button (overrides accentColor to red)
              Button {
                Task { await friendManager.declineFriendInvite(invite) }
              } label: {
                Text("Decline")
                  .font(.body.bold())
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 12)
                  .background(Color.accentColor.opacity(0.2))
                  .foregroundColor(Color.accentColor)
                  .clipShape(Capsule())
              }
              .accentColor(.red)
              .buttonStyle(PlainButtonStyle())
              .shadow(color: .black.opacity(0.02), radius: 2, x: 0, y: 1)
            }
          }
          .padding(.vertical, 4)
          .padding(.horizontal)
          .foregroundStyle(.primary)
        }
        
      } else {
        // sender がまだロードされていない間のプレースホルダー
        HStack {
          ProgressView()
            .progressViewStyle(.circular)
          Text("Loading...")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding()
      }
    }
    .task {
      // 非同期で sender をフェッチ
      self.sender = await accountManager.fetchUser(id: invite.senderId)
    }
  }
}

