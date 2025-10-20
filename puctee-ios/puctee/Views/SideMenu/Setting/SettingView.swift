//
//  SettingView.swift
//  puctee
//
//  Created by kj on 6/9/25.
//

import SwiftUI

struct SettingView: View {
  @Environment(\.accountManager) private var accountManager: AccountManager
  @State private var showLogoutConfirmation = false
  @State private var showDeleteConfirmation = false
  @State private var isLoggingOut = false
  @State private var isDeletingAccount = false
  @State private var deleteError: String?
  
  private var appVersion: String {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    return "\(version) (\(build))"
  }
  
  var body: some View {
    List {
      // Account Management Section
      Section {
        Button(role: .destructive) {
          showLogoutConfirmation = true
        } label: {
          HStack {
            Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
            Spacer()
            if isLoggingOut {
              ProgressView()
                .progressViewStyle(.circular)
            }
          }
        }
        .disabled(isLoggingOut)
        
        // Account deletion
        Button(role: .destructive) {
          showDeleteConfirmation = true
        } label: {
          HStack {
            Label("Delete Account", systemImage: "trash")
            Spacer()
            if isDeletingAccount {
              ProgressView()
                .progressViewStyle(.circular)
            }
          }
        }
        .disabled(isDeletingAccount || isLoggingOut)
      } header: {
        Text("Account Management")
      } footer: {
        Text("Deleting your account will permanently remove all your data")
          .font(.caption)
      }
      
      // Support Section
      Section("Support Information") {
        HStack {
          Label("App Version", systemImage: "info.circle")
          Spacer()
          Text(appVersion)
            .foregroundStyle(.secondary)
        }
      }
    }
    .navigationTitle("Settings")
    .navigationBarTitleDisplayMode(.inline)
    .confirmationDialog(
      "Log Out?",
      isPresented: $showLogoutConfirmation,
      titleVisibility: .visible
    ) {
      Button("Log Out", role: .destructive) {
        Task {
          isLoggingOut = true
          await accountManager.logout()
          isLoggingOut = false
        }
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("You will need to log in again after logging out")
    }
    .confirmationDialog(
      "Delete Account?",
      isPresented: $showDeleteConfirmation,
      titleVisibility: .visible
    ) {
      Button("Delete", role: .destructive) {
        Task {
          isDeletingAccount = true
          do {
            try await accountManager.deleteAccount()
          } catch {
            deleteError = error.localizedDescription
          }
          isDeletingAccount = false
        }
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("This action cannot be undone. All your data will be permanently deleted.")
    }
    .alert("Deletion Error", isPresented: .constant(deleteError != nil)) {
      Button("OK") {
        deleteError = nil
      }
    } message: {
      if let error = deleteError {
        Text(error)
      }
    }
  }
}
