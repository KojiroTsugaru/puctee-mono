//
//  EmptyFriendsView.swift
//  puctee
//
//  Created by kj on 7/4/25.
//

import SwiftUI

struct EmptyFriendsView: View {
  var body: some View {
    VStack(spacing: 16) {
      // Icon that expands to fill the screen width
      Image(systemName: "person.2.slash")
        .resizable()
        .scaledToFit()
      // Max width of screen, max height of 200 points
        .frame(width: 64, height: 64)
        .foregroundStyle(.secondary)
      
      // Text that expands to fill the screen width
      Text("No friends")
        .font(.headline)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
    }
    // Zero horizontal padding, only vertical padding
    .padding(.vertical, 24)
    // Expand VStack itself to fill the screen
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color(UIColor.systemBackground))
  }
}

struct EmptyFriendsView_Previews: PreviewProvider {
  static var previews: some View {
    EmptyFriendsView()
  }
}

