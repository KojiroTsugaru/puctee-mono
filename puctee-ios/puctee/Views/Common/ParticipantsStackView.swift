//
//  ParticipantsStackView.swift
//  puctee
//
//  Created by kj on 5/10/25.
//

import SwiftUI
import Kingfisher

struct ParticipantsStackView: View {
  let participants: [User]
  
  init(for participants: [User]) {
    self.participants = participants
  }
  
  var body: some View {
    HStack(spacing: -8) {
      // Display up to 3 avatars
      ForEach(participants.prefix(3), id: \.id) { participant in
        KFImage(participant.profileImageUrl)
          .placeholder {
            PlaceholderInitial()
              .frame(width: 32, height: 32)
          }
          .resizable()
          .scaledToFill()
          .frame(width: 32, height: 32)
          .clipped()
          .clipShape(Circle())
          .overlay(Circle().stroke(.gray, lineWidth: 1))
      }
      
      // Show extra count
      if participants.count > 3 {
        let extra = participants.count - 3
        Text("+\(extra)")
          .font(.caption2)
          .foregroundColor(.primary)
          .frame(width: 32, height: 32)
          .background(Circle().fill(Color.secondary.opacity(0.1)))
          .overlay(Circle().stroke(Color.white, lineWidth: 1))
      }
    }
  }
}
