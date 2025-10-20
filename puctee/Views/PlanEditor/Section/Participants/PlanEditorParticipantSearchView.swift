import SwiftUI

// MARK: - User Search View
struct PlanEditorParticipantSearchView: View {
  @Bindable var vm: PlanEditorViewModel
  @State private var selectedUsers: [User] = []
  @State private var query: String = ""
  @State private var searchResults: [User] = []
  @State private var friends: [User] = []
  
  @Environment(\.dismiss) var dismiss
  @Environment(\.accountManager) private var accountManager
  
  private var otherParticipants: [User] {
    selectedUsers.filter { $0.id != accountManager.currentUser?.id }
  }
  
  var body: some View {
    VStack {
      ParticipantSearchBar(text: $query)
      
      // Participant list view
      if !otherParticipants.isEmpty {
        ParticipantsSearchCurrentParticipantsView(selectedUsers: selectedUsers, onRemove: { user in
          withAnimation(.easeInOut(duration: 0.2)){
            selectedUsers.removeAll { $0.id == user.id }
          }
        })
        .padding(16)
      }
      
      ScrollView(.vertical) {
        ForEach(displayedUsers) { user in
          ParticipantSearchListCell(
            user: user,
            isSelected: selectedUsers.contains(user)
          )
          .contentShape(Rectangle())
          .onTapGesture { toggleSelection(of: user) }
          Divider()
        }
      }
      .padding(.vertical, 4)
      Spacer()
    }
    .listStyle(.plain)
    .navigationTitle("Find Users")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        Button {
          // TODO: Add processing
          vm.participants = selectedUsers
          dismiss()
        } label: {
          Text("Save")
            .font(.subheadline).bold()
            .padding(.vertical, 8).padding(.horizontal, 16)
            .background(.accent)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
      }
    }
    .overlay(content: {
      if displayedUsers.isEmpty {
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
    .task {
      // Get friends when initially displayed / query is empty
      
      // Copy contents of vm.participants to selectedUser
      selectedUsers = vm.participants
    }
  }
  
  /// Display target
  private var displayedUsers: [User] {
    if query.isEmpty {
      return friends
    } else {
      return searchResults
    }
  }
  
  // Selection toggle
  private func toggleSelection(of user: User) {
    if let idx = selectedUsers.firstIndex(of: user) {
      withAnimation(.easeInOut(duration: 0.2)) {
        selectedUsers.remove(at: idx)
      }
    } else {
      withAnimation(.easeInOut(duration: 0.2)) {
        selectedUsers.append(user)
      }
    }
  }
}
