//
//  ParticipantsMapAnnotationItem.swift
//  puctee
//
//  Created by kj on 7/2/25.
//

import SwiftUI
import MapKit
import Kingfisher

struct ParticipantsMapAnnotationItem: View {
  let displayName: String
  let profileImageUrl: URL?
  
  init(location: LocationShare) {
    self.displayName = location.displayName
    self.profileImageUrl = URL(string: location.profileImageUrl ?? "")
  }
  
  init(user: User) {
    self.displayName = user.displayName
    self.profileImageUrl = user.profileImageUrl
  }
  
  var body: some View {
    VStack(spacing: 8) {
      // コールアウト
      Text(displayName)
        .font(.caption).bold()
        .foregroundStyle(.white)
        .padding(8)
        .background(Color.accent)
        .cornerRadius(8)
      
      // カスタムピン
      KFImage(profileImageUrl)
        .placeholder {
          PlaceholderInitial()
            .frame(width: 60, height: 60)
            .background(Color.white.opacity(0.3))
        }
        .resizable()
        .scaledToFill()
        .frame(width: 60, height: 60)
        .clipShape(Circle())
        .overlay(
          Circle()
            .stroke(Color.accent, lineWidth: 1)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0.5, y: 1)
          )
    }
  }
}

#Preview {
  Map(initialPosition: .automatic) {
    Annotation("sample", coordinate: SampleData.yoyogiPark.coordinate) {
      ParticipantsMapAnnotationItem(user: SampleData.alice)
    }
    .annotationTitles(.hidden)
    .mapOverlayLevel(level: .aboveLabels)
  }
}
