//
//  FriendSearchBar.swift
//  puctee
//
//  Created by kj on 6/8/25.
//

import SwiftUI

struct FriendSearchBar: View {
  @Binding var text: String
  var placeholder: String = "Name, Username..."
  
  var body: some View {
    HStack {
      Image(systemName: "magnifyingglass")
        .foregroundColor(.secondary)
      TextField(placeholder, text: $text)
        .autocorrectionDisabled(true)
        .textInputAutocapitalization(.none)
      if !text.isEmpty {
        Button(action: { text = "" }) {
          Image(systemName: "xmark.circle.fill")
            .foregroundColor(.secondary)
        }
      }
    }
    .padding(8)
    .background(.regularMaterial)
    .cornerRadius(10)
    .padding(.horizontal)
  }
}
