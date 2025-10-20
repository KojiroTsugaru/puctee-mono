//
//  AppRouter.swift
//  puctee
//
//  Created by kj on 5/19/25.
//

import Foundation

final class AppRouter: ObservableObject {
  @Published var invitedPlanId: String? = nil
  
  func handleDeepLink(_ url: URL) {
    guard url.pathComponents.count >= 3,
          url.pathComponents[1] == "plan" else { return }
    invitedPlanId = url.pathComponents[2]
  }
}
