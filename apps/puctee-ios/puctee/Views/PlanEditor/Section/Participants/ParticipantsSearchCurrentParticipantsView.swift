//
//  CurrentParticipantsView.swift
//  puctee
//
//  Created by kj on 5/22/25.
//

import SwiftUI
import Kingfisher

/// View to display currently selected participants and communicate removal actions to the parent
struct ParticipantsSearchCurrentParticipantsView: View {
  // List of selected users (excluding self)
  let selectedUsers: [User]
  /// Closure to call when a user is removed
  let onRemove: (User) -> Void
  
  @Environment(\.accountManager) private var accountManager
  
  // List of participants excluding myself (currentUser)
  private var allParticipantsButMe: [User] {
    selectedUsers.filter { $0.id != accountManager.currentUser?.id }
  }
  
  var body: some View {
    HStack(spacing: 16) {
      ForEach(allParticipantsButMe) { participant in
        ParticipantIcon(participant: participant, onRemove: onRemove)
      }
      Spacer()
    }
  }
}

struct ParticipantIcon: View {
  let participant: User
  let onRemove: (User) -> Void
  
  var body: some View {
    VStack(spacing: 4) {
      ZStack(alignment: .topTrailing) {
        KFImage(participant.profileImageUrl)
          .placeholder {
            PlaceholderInitial()
              .frame(width: 40, height: 40)
              .clipShape(Circle())
              .overlay(Circle().stroke(.gray, lineWidth: 1))
          }
          .resizable()
          .scaledToFill()
          .frame(width: 40, height: 40)
          .clipped()
          .clipShape(Circle())
          .overlay(Circle().stroke(.white, lineWidth: 1))
        
        // Delete button
        Button(action: { onRemove(participant) }) {
          Image(systemName: "xmark")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.gray)
            .frame(width: 8, height: 8)
            .padding(6)
            .background(
              Circle()
                .fill(Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(0.15), radius: 1, x: 1, y: 1)
            )
        }
        .offset(x: 4, y: -4)
      }
      
      Text(participant.displayName)
        .foregroundStyle(.secondary)
        .font(.caption)
        .lineLimit(1)
    }
  }
}

#Preview {
  ParticipantIcon(participant: SampleData.alice, onRemove: {_ in })
}

