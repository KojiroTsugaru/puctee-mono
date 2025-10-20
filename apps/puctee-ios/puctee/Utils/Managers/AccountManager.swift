//
//  AccountManager.swift
//  puctee
//
//  Created by kj on 5/8/25.
//
import SwiftUI
import Observation
import Kingfisher

@Observable class AccountManager {
  var currentUser: User? = nil
  var isAuthenticated: Bool = false
  var didRestoreSession = false
  
  func signup(username: String,
              displayName: String,
              email: String,
              password: String,
              imageData: Data?) async throws {
    let _ = try await AuthService.shared.signup(
      email: email,
      displayName: displayName,
      username: username,
      password: password
    )
  }
  
  /// login with email
  func login(email: String, password: String) async throws {
      let _ = try await AuthService.shared.login(email: email, password: password)
      await fetchCurrentUser()
  }
  
  /// login with username
  func login(username: String, password: String) async {
    do {
      let _ = try await AuthService.shared.login(username: username, password: password)
      await fetchCurrentUser()
    } catch {
      print("Login failed: \(error)")
    }
  }
  
  /// logout
  func logout() async {
    do {
      try await AuthService.shared.logout()
      currentUser = nil
      isAuthenticated = false
    } catch {
      print("Logout failed: \(error)")
    }
  }
  
  /// fetch current user -> refresh on main thread
  func fetchCurrentUser() async {
    do {
      let user = try await UserService.shared.fetchCurrentUser()
      await MainActor.run {
        self.currentUser = user
        self.isAuthenticated = true
      }
    } catch {
      print("Fetch current user failed: \(error)")
      
      /// If the user cannot be retrieved, send them to the login screen just in case.
      await MainActor.run {
        self.currentUser = nil
        self.isAuthenticated = false
      }
    }
  }
  
  /// fetch user by user id
  func fetchUser(id: Int) async -> User? {
    do {
      return try await UserService.shared.fetchUser(id: id)
    } catch {
      print("Fetch user \(id) failed: \(error)")
      return nil
    }
  }
  
  /// upload profile image and get the url to the resource on S3
  func uploadProfileImage(imageData: Data?) async throws {
    // remove cache of current profile image path
    if let urlString = self.currentUser?.profileImageUrl?.absoluteString {
      try await ImageCache.default.removeImage(forKey: urlString)
    }
    
    // make a request to update image
    let response = try await UserService.shared.uploadProfileImage(imageData: imageData!)
    
    // add cacheBuster to fource refresh KFImage on all screens
    let cacheBuster = "?v=\(Int(Date().timeIntervalSince1970))"
    let bustedUrlString = response.url.absoluteString + cacheBuster
    guard let bustedUrl = URL(string: bustedUrlString) else { return }
    
    await MainActor.run { self.currentUser?.profileImageUrl = bustedUrl }
  }
  /// Called when the app starts or when ContentView appears.
  /// If the token is within its validity period, fetch the currentUser and set isAuthenticated = true without requiring a re-login.
  func restoreSession() async {
    
    // It's Ok to call fetchCurrentUser() only
    // This func is checking if refresh token (exp 30 days) is still valid.
    // If refresh token is not valid, then currentUser stays as nil and signup view appears.
    // If refresh token is valid, go to home view.
    await fetchCurrentUser()
    await MainActor.run { self.didRestoreSession = true }
  }
}

// MARK: Environment Key
extension EnvironmentValues {
  var accountManager: AccountManager {
    get {
      self[AccountManagerKey.self]
    } set {
      self[AccountManagerKey.self] = newValue
    }
  }
}

private struct AccountManagerKey: EnvironmentKey {
  static let defaultValue: AccountManager = AccountManager()
}
