//
//  SignupProfileIconView.swift
//  puctee
//
//  Created by kj on 5/8/25.
//

import SwiftUI
import PhotosUI

struct SignupProfileIconView: View {
  @Environment(\.accountManager) private var accountManager
  @Bindable var vm: AuthViewModel
  
  var body: some View {
    VStack(spacing: 40) {
      Spacer()
      Text("Please set up your\nprofile picture")
        .multilineTextAlignment(.center)
        .font(.title3).fontWeight(.bold)
      
      ZStack {
        if let image = vm.profileImage {
          Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .clipShape(.circle)
        } else {
          Image(systemName: "person.crop.circle")
            .resizable()
            .foregroundStyle(.secondary)
        }
      }
      .frame(width: 100, height: 100)
      .padding()
      
      PhotosPicker(selection: $vm.selectedPhotoItem, matching: .images) {
        Text(vm.profileImage == nil ? "Select a photo" : "Change photo")
          .font(.headline).fontWeight(.semibold)
          .foregroundColor(.white)
          .frame(width: 200)
          .padding(.vertical, 14)
          .background(RoundedRectangle(cornerRadius: 12)
            .fill(Color.accentColor))
      }
      
      Spacer()
      
      VStack {
        if let signUpError = vm.signUpError {
          Text(signUpError)
            .font(.caption)
            .foregroundStyle(.red)
        }
        
        if let loadingMessage = vm.loadingMessage?.rawValue {
          HStack {
            ProgressView()
            Text(loadingMessage)
          }
        }
        
        Button {
          Task { await vm.signup(using: accountManager) }
        } label: {
          Text(vm.profileImage == nil ? "Register without setting a photo" : "Register")
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
      }
    }
    .padding(.horizontal, 24)
    // TODO: Show an alert saying "Failed to upload profile picture. Please try again later."
    .alert("Profile Image Upload Failed", isPresented: Binding<Bool>(
      get: { vm.imageUploadError != nil },
      set: { newValue in
        if !newValue { vm.imageUploadError = nil }
      })
    ) {
      Button("OK") {
        vm.imageUploadError = nil
        Task {
          await accountManager.fetchCurrentUser()
        }
      }
    } message: {
      Text(vm.imageUploadError ?? "")
    }
  }
}
