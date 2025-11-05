//
//  UserActionMenu.swift
//  puctee
//
//  Created by kj on 11/4/25.
//

import SwiftUI

struct UserActionMenu: View {
  let user: User
  @State private var showBlockConfirmation = false
  @State private var showReportSheet = false
  @State private var isBlocked = false
  @State private var isLoading = false
  
  var body: some View {
    Menu {
      Button(role: .destructive) {
        showReportSheet = true
      } label: {
        Label("Report User", systemImage: "exclamationmark.bubble")
      }
      
      Divider()
      
      if isBlocked {
        Button {
          unblockUser()
        } label: {
          Label("Unblock User", systemImage: "person.crop.circle.badge.checkmark")
        }
      } else {
        Button(role: .destructive) {
          showBlockConfirmation = true
        } label: {
          Label("Block User", systemImage: "person.crop.circle.badge.xmark")
        }
      }
    } label: {
      Image(systemName: "ellipsis.circle")
        .font(.system(size: 20))
        .foregroundColor(.secondary)
    }
    .task {
      await checkIfBlocked()
    }
    .confirmationDialog(
      "Block \(user.displayName)?",
      isPresented: $showBlockConfirmation,
      titleVisibility: .visible
    ) {
      Button("Block", role: .destructive) {
        blockUser()
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Blocked users cannot send you friend requests or invite you to plans. You won't see their content.")
    }
    .sheet(isPresented: $showReportSheet) {
      ReportContentSheet(
        contentType: .userProfile,
        contentId: nil,
        reportedUserId: user.id
      )
    }
  }
  
  private func checkIfBlocked() async {
    do {
      isBlocked = try await ModerationService.shared.isUserBlocked(userId: user.id)
    } catch {
      print("Failed to check block status: \(error)")
    }
  }
  
  private func blockUser() {
    isLoading = true
    Task {
      do {
        try await ModerationService.shared.blockUser(userId: user.id)
        await MainActor.run {
          isBlocked = true
          isLoading = false
        }
      } catch {
        await MainActor.run {
          isLoading = false
        }
        print("Failed to block user: \(error)")
      }
    }
  }
  
  private func unblockUser() {
    isLoading = true
    Task {
      do {
        try await ModerationService.shared.unblockUser(userId: user.id)
        await MainActor.run {
          isBlocked = false
          isLoading = false
        }
      } catch {
        await MainActor.run {
          isLoading = false
        }
        print("Failed to unblock user: \(error)")
      }
    }
  }
}
