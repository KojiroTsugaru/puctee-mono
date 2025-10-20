//
//  SignupPasswordView.swift
//  puctee
//
//  Created by kj on 5/8/25.
//

import SwiftUI

struct SignupPasswordView: View {
  @Bindable var vm: AuthViewModel
  @State var confirmPassword: String = ""
  @State private var showAttemptedSubmit = false
  
  @FocusState private var isPasswordFocused: Bool
  @FocusState private var isConfirmFocused: Bool
  
  // MARK: - Validation rules
  private var isLengthValid: Bool {
    vm.password.count >= 8
  }
  private var hasUppercase: Bool {
    vm.password.range(of: "[A-Z]", options: .regularExpression) != nil
  }
  private var hasDigit: Bool {
    vm.password.range(of: "[0-9]", options: .regularExpression) != nil
  }
  private var passwordsMatch: Bool {
    !confirmPassword.isEmpty && vm.password == confirmPassword
  }
  
  // Whether all rules are passed
  private var isPasswordValid: Bool {
    isLengthValid && hasUppercase && hasDigit
  }
  
  // Condition to enable the Next button
  private var canProceed: Bool {
    isPasswordValid && passwordsMatch
  }
  
  var body: some View {
    VStack(spacing: 24) {
      Spacer()
      
      // Title
      Text("Please enter your password")
        .font(.title3).fontWeight(.bold)
        .multilineTextAlignment(.center)
      
      // Password input field
      SecureField("Password", text: $vm.password)
        .focused($isPasswordFocused)
        .padding()
        .background(
          RoundedRectangle(cornerRadius: 12)
            .stroke(isPasswordFocused
                    ? Color.accentColor
                    : Color.secondary.opacity(0.3),
                    lineWidth: 1)
        )
      
      // Password confirmation input field
      SecureField("Confirm Password", text: $confirmPassword)
        .focused($isConfirmFocused)
        .padding()
        .background(
          RoundedRectangle(cornerRadius: 12)
            .stroke(isConfirmFocused
                    ? Color.accentColor
                    : Color.secondary.opacity(0.3),
                    lineWidth: 1)
        )
      
      if !isPasswordValid {
        Text("※ Please enter at least 8 characters including upper and lower case letters and numbers")
          .font(.caption)
          .foregroundColor(.red)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 8)
      }
      
      // Error when passwords do not match
      if showAttemptedSubmit && !passwordsMatch {
        Text("※ Passwords do not match")
          .font(.caption)
          .foregroundColor(.red)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 8)
      }
      
      // Signup error message
      if let signUpError = vm.signUpError {
        Text(signUpError)
          .font(.caption)
          .foregroundColor(.red)
      }
      
      // Next button
      Button {
        showAttemptedSubmit = true
        if canProceed {
          vm.path.append(.signupProfileIcon)
        }
      } label: {
        Text("Next")
          .frame(width: 200)
      }
      .buttonStyle(.borderedProminent)
      .controlSize(.large)
      .disabled(!canProceed)
      .opacity(canProceed ? 1 : 0.6)
      
      Spacer()
    }
    .padding(.horizontal, 24)
  }
}
