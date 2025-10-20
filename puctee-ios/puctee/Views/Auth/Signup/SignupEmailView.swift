//
//  SignupEmailView.swift
//  puctee
//
//  Created by kj on 5/8/25.
//

import SwiftUI

struct SignupEmailView: View {
  @Binding var email: String
  var onNext: () -> Void
  @FocusState private var isFocused: Bool
  @State private var emailValidateErrorMessage = ""
  
  var body: some View {
    VStack(spacing: 40) {
      Spacer()
      
      Text("Please enter your email address")
        .multilineTextAlignment(.center)
        .font(.title3)
        .fontWeight(.bold)
      
      // Input field
      HStack {
        TextField("Enter your email address", text: $email)
          .keyboardType(.emailAddress)
          .focused($isFocused)
          .autocorrectionDisabled()
          .textInputAutocapitalization(.none)
      }
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 12)
          .stroke(
            isFocused
            ? Color.accentColor
            : Color.secondary.opacity(0.3),
            lineWidth: 1
          )
      )
      
      Text(emailValidateErrorMessage)
        .font(.caption)
        .foregroundStyle(.red)
      
      // Next button
      Button {
        Task {
          await didTapNext(email)
        }
      } label: {
        Text("Next")
          .frame(width: 200)
      }
      .buttonStyle(.borderedProminent)
      .controlSize(.large)
      .disabled(email.isEmpty)
      .opacity(email.isEmpty ? 0.6 : 1.0)
      
      Spacer()
    }
    .padding(.horizontal, 24)
  }
  
  private func didTapNext(_ email: String) async {
    // validate username
    do {
      let isAvailable = try await AuthService.shared.validateEmail(email)
      
      if isAvailable {
        emailValidateErrorMessage = ""
        onNext()
      } else {
        emailValidateErrorMessage = "This email address is already in use."
      }
    } catch AuthError.invalidEmailFormat {
      emailValidateErrorMessage = "The email address is incorrect."
    } catch {
      emailValidateErrorMessage = "A communication error has occurred."
    }
  }
}

struct SignupEmailView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      SignupEmailView(email: .constant(""), onNext: {})
    }
    .preferredColorScheme(.light)
    
    NavigationStack {
      SignupEmailView(email: .constant("kojirotsugaru@gmai"), onNext: {})
    }
    .preferredColorScheme(.dark)
  }
}

