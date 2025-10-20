//
//  AuthRootView.swift
//  puctee
//
//  Created by kj on 6/7/25.
//

import SwiftUI

struct AuthRootView: View {
  
  @Bindable var vm: AuthViewModel
  
  var body: some View {
    VStack {
      Spacer()
      Text("Welcome!")
        .font(.largeTitle)
      Spacer()
      
      Button {
        vm.path.append(.signupName)
      } label: {
        Text("Get Started")
          .foregroundStyle(.white)
          .font(.headline)
          .frame(width: 200)
          .padding()
          .background(Color.accentColor)
          .cornerRadius(16)
      }
      .padding(.bottom)

      Text("Do you already have a puctee account?")
        .font(.headline)
      Button {
        vm.path.append(.login)
      } label: {
        Text("Login")
          .foregroundStyle(.accent)
          .font(.headline)
      }
      .padding(.bottom, 24)
      
      VStack {
        HStack {
          Text("Terms of Use")
          Text("and")
          Text("Privacy Policy")
        }
        .padding(4)
        Text("By using puctee, you agree to the Terms of Use and \nPrivacy Policy.")
          .multilineTextAlignment(.center)
      }
      .font(.caption)
      .padding(.bottom, 24)
    }
  }
}

#Preview {
  AuthRootView(vm: .init())
}
