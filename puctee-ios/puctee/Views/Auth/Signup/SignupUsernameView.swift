//
//  SignupUserIdView.swift
//  puctee
//
//  Created by kj on 5/8/25.
//

import SwiftUI

struct SignupUsernameView: View {
  @Binding var username: String
  var onNext: () -> Void
  @FocusState private var isFocused: Bool
  @State private var usernameErrorMessage = ""
  
  var body: some View {
    VStack(spacing: 40) {
      Spacer()
      
      Text("Please enter your username")
        .multilineTextAlignment(.center)
        .font(.title3)
        .fontWeight(.bold)
      
      // Input field
      HStack {
        TextField("Enter your username", text: $username)
          .focused($isFocused)
          .autocorrectionDisabled()
          .textInputAutocapitalization(.words)
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
      
      Text(usernameErrorMessage)
        .font(.caption)
        .foregroundStyle(.red)
      
      // Next button
      Button {
        Task {
          await didTapNext(username: username)
        }
      } label: {
        Text("Next")
          .frame(width: 200)
      }
      .buttonStyle(.borderedProminent)
      .controlSize(.large)
      .disabled(username.isEmpty)
      .opacity(username.isEmpty ? 0.6 : 1.0)
      
      Spacer()
    }
    .padding(.horizontal, 24)
  }
  
  private func didTapNext(username: String) async {
    // validate username
    do {
      let isAvailable = try await AuthService.shared.validateUsername(username)
      
      if isAvailable {
        usernameErrorMessage = ""
        onNext()
      } else {
        usernameErrorMessage = "This username is already in use."
      }
    } catch {
      usernameErrorMessage = "A communication error has occurred."
    }
  }
}

struct SignupUsernameView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      SignupUsernameView(username: .constant(""), onNext: {})
    }
    .preferredColorScheme(.light)
    
    NavigationStack {
      SignupUsernameView(username: .constant("Kojiro"), onNext: {})
    }
    .preferredColorScheme(.dark)
  }
}

