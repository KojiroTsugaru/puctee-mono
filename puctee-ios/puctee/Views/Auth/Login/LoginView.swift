//
//  LoginView.swift
//  puctee
//
//  Created by kj on 7/28/25.
//

import SwiftUI

struct LoginView: View {
  @Bindable var vm: AuthViewModel
  @FocusState private var isEmailFocused: Bool
  @FocusState private var isPasswordFocused: Bool
  
  @Environment(\.accountManager) private var accountManager
  
  private var isLengthValid: Bool {
    vm.loginPassword.count >= 8
  }
  
  var body: some View {
    VStack(spacing: 40) {
      Spacer()
      
      VStack(spacing: 20) {
        Text("Login")
          .multilineTextAlignment(.center)
          .font(.title)
          .fontWeight(.bold)
        
        Text("Welcome back! Enter your email and password")
          .multilineTextAlignment(.center)
          .foregroundStyle(.gray)
          .font(.caption)
      }
      
      
      VStack {
        // Email address input field
        TextField("Enter your email address", text: $vm.loginEmail)
          .keyboardType(.emailAddress)
          .focused($isEmailFocused)
          .autocorrectionDisabled()
          .textInputAutocapitalization(.none)
          .padding()
          .background(
            RoundedRectangle(cornerRadius: 12)
              .stroke(
                isEmailFocused
                ? Color.accentColor
                : Color.secondary.opacity(0.3),
                lineWidth: 1
              )
          )
        
        // Password input field
        SecureField("Password", text: $vm.loginPassword)
          .focused($isPasswordFocused)
          .padding()
          .background(
            RoundedRectangle(cornerRadius: 12)
              .stroke(isPasswordFocused
                      ? Color.accentColor
                      : Color.secondary.opacity(0.3),
                      lineWidth: 1)
          )
      }
      
      // Login error message
      if let loginError = vm.loginError {
        Text(loginError)
          .font(.caption)
          .foregroundColor(.red)
      }
      
      // loading message
      if let loadingMessage = vm.loadingMessage?.rawValue {
        HStack {
          ProgressView()
          Text(loadingMessage)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
      }
      
      // Login button
      Button {
        if isLengthValid {
          Task { await vm.login(using: accountManager) }
        }
      } label: {
        Text("Login")
          .frame(width: 200)
      }
      .buttonStyle(.borderedProminent)
      .controlSize(.large)
      .disabled(!isLengthValid)
      .opacity(isLengthValid ? 1 : 0.6)
      
      Spacer()
    }
    .padding(.horizontal, 24)
  }
}
