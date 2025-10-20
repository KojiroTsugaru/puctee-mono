//
//  PlaceholderInitial.swift
//  puctee
//
//  Created by kj on 5/14/25.
//

import SwiftUI

struct PlaceholderInitial: View {
  @Environment(\.accountManager) private var accountManager
  
  var body: some View {
    Text(initial)
      .font(.headline)
      .foregroundColor(.gray)
  }
  
  private var initial: String {
    accountManager.currentUser?.displayName.first.map { String($0) } ?? "?"
  }
}
