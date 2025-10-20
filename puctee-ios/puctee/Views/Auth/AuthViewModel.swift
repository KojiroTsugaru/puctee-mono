//
//  AuthViewModel.swift
//  puctee
//
//  Created by kj on 5/13/25.
//

import Observation
import SwiftUI
import PhotosUI

@Observable class AuthViewModel {
  enum Step: Hashable {
    case signupName, signupUserId, signupEmail, signupPassword, signupProfileIcon, login
  }
  var path: [Step] = []
  var displayName = ""
  var username = ""
  var email = ""
  var password = ""
  var profileImage: UIImage?
  var profileImageData: Data?
  var loginEmail = ""
  var loginPassword = ""
  var loginError: String?
  var signUpError: String?
  var imageUploadError: String?
  var loadingMessage: LoadingMessage?
  
  enum LoadingMessage: String {
    case signup = "Registering user information..."
    case login = "Logging in..."
    case uploadingPofileIcon = "Uploading profile picture..."
  }
  
  var selectedPhotoItem: PhotosPickerItem? {
    didSet {
      Task {
        guard
          let item = selectedPhotoItem,
          let data = try? await item.loadTransferable(type: Data.self),
          let uiImage = UIImage(data: data)
        else { return }
        profileImageData = data
        profileImage = uiImage
      }
    }
  } 

  /// Upload profile picture at the same time as user registration
  // Press the final registration button -> Registering user -> Uploading profile picture
  // Handle errors for both user registration and profile picture upload
  // If profile picture upload fails, show an alert
  // with the message "Failed to upload profile picture. Please try again later." and navigate to the home screen.
  func signup(using accountManager: AccountManager) async {
    // Start signup
    loadingMessage = .signup
    signUpError = nil
    defer { loadingMessage = nil } // Always cleared when exiting this function
    
    do {
      try await accountManager.signup(
        username: username,
        displayName: displayName,
        email: email,
        password: password,
        imageData: profileImageData
      )
    } catch {
      // Return immediately if signup fails
      print("signUp error:", error)
      signUpError = "Sign up failed. Please try again."
      return
    }
  
    // Upload profile picture
    loadingMessage = .uploadingPofileIcon
    do {
      try await accountManager.uploadProfileImage(imageData: profileImageData)
    } catch {
      // Navigate to home even if only the image fails
      imageUploadError = "Failed to upload profile picture. Please try again later."
      return
    }
    
    // Finally, fetch the currentUser
    await accountManager.fetchCurrentUser()
  }
  
  func login(using accountManager: AccountManager) async {
    // Start login
    loadingMessage = .login
    loginError = nil
    defer { loadingMessage = nil } // Always cleared when exiting this function
    
    do {
      try await accountManager.login(email: loginEmail, password: loginPassword)
    } catch {
      // login failed
      print("login error: ", error)
      loginError = "Login failed."
      return
    }
  }
}
