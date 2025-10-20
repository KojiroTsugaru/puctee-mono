//
//  FriendSearchView.swift
//  puctee
//
//  Created by kj on 6/8/25.
//

import SwiftUI

// MARK: - User Search View
struct FriendSearchView: View {
  @State private var query: String = ""
  @State private var searchResults: [User] = []
  
  @Environment(\.accountManager) private var accountManager
  
  var body: some View {
    VStack {
      ParticipantSearchBar(text: $query)
      
      ScrollView(.vertical) {
        ForEach(searchResults) { user in
          UserProfileFriendListCell(user: user)
          .contentShape(Rectangle())
          Divider()
        }
      }
      .padding(.vertical, 4)
      Spacer()
    }
    .listStyle(.plain)
    .navigationTitle("Find Users")
    .navigationBarTitleDisplayMode(.inline)
    .overlay(content: {
      if searchResults.isEmpty {
        ContentUnavailableView.search(text: query)
          .listRowBackground(Color.clear)
      }
    })
    .onChange(of: query) { newQuery in
      Task {
        if newQuery.isEmpty {
          // Clear search results if search query is empty
          searchResults = []
        } else {
          do {
            searchResults = try await UserService.shared.searchUsers(query: newQuery)
          } catch {
            print("SearchUsers error: \(error)")
            searchResults = []
          }
        }
      }
    }
  }
}
