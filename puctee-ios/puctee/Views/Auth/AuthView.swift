//
//  SignupView.swift
//  puctee
//
//  Created by kj on 5/8/25.
//

import SwiftUI
import PhotosUI

// MARK: - AuthRootView
struct AuthView: View {
  @Environment(\.accountManager) var accountManager: AccountManager
  @State private var vm: AuthViewModel = .init()
  
  var body: some View {
    NavigationStack(path: $vm.path) {
      AuthRootView(vm: vm)
      .navigationDestination(for: AuthViewModel.Step.self) { step in
        switch step {
          case .signupName:
            SignupNameView(name: $vm.displayName) { vm.path.append(.signupUserId) }
          case .signupUserId:
            SignupUsernameView(username: $vm.username) { vm.path.append(.signupEmail) }
          case .signupEmail:
            SignupEmailView(email: $vm.email) { vm.path.append(.signupPassword) }
          case .signupPassword:
            SignupPasswordView(vm: vm)
          case .signupProfileIcon:
            SignupProfileIconView(vm: vm)
          case .login:
            LoginView(vm: vm)
        }
      }
    }
  }
}

#Preview {
  AuthView()
}

