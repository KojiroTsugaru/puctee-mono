//
//  ParticipantSearchListCell.swift
//  puctee
//
//  Created by kj on 5/20/25.
//

import SwiftUI
import Kingfisher

struct ParticipantSearchListCell: View {
  let user: User
  var isSelected: Bool
  
  var body: some View {
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
        .overlay(Circle().stroke(.white, lineWidth: 1))
      
      VStack(alignment: .leading, spacing: 2) {
        Text(user.displayName)
          .font(.body)
        Text("@\(user.username)")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      Spacer()
      Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
        .resizable()
        .scaledToFit()
        .frame(width: 24, height: 24)
        .foregroundStyle(.blue)
        .padding(.trailing, 8)
    }
    .padding(.vertical, 4)
    .padding(.horizontal)
  }
}
