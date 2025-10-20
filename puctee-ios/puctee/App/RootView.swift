//
//  RootView.swift
//  puctee
//
//  Created by kj on 5/8/25.
//

import SwiftUI

struct RootView: View {
  @Environment(\.accountManager) private var accountManager
  
  var body: some View {
    Group {
      // placeholder while restoring session
      if !accountManager.didRestoreSession {
        VStack {
          Image("AppIconPlaceholder")
            .resizable()
            .scaledToFit()
            .frame(width: 100, height: 100)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .transition(.opacity)
      } else if accountManager.isAuthenticated && accountManager.currentUser != nil {
        HomeView()
          .transition(.opacity)
      } else {
        AuthView()
          .transition(.opacity)
      }
    }
    .animation(.easeInOut(duration: 0.3), value: accountManager.didRestoreSession)
    .animation(.easeInOut(duration: 0.3), value: accountManager.isAuthenticated)
    // restore session once on launch
    .task {
      await accountManager.restoreSession()
    }
  }
}

#Preview {
    RootView()
}
