//
//  pucteeApp.swift
//  puctee
//
//  Created by kj on 5/8/25.
//

import SwiftUI
import UserNotifications
import BackgroundTasks

@main
struct pucteeApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  
  @State private var accountManager = AccountManager()
  @State private var planManager: PlanManager
  @State private var trustStatsManager = TrustStatsManager()
  @State private var friendManager = FriendManager()
  
  init() {
    let accountManager = AccountManager()
    self._accountManager = State(initialValue: accountManager)
    self._planManager = State(initialValue: PlanManager(accountManager: accountManager))
  }
  @StateObject private var deepLink = DeepLinkHandler.shared
  @StateObject private var modal = ModalCoordinator.shared
  @Environment(\.scenePhase) private var scenePhase
   
    var body: some Scene {
        WindowGroup {
            RootView()
              .environment(\.accountManager, accountManager)
              .environment(\.planManager, planManager)
              .environment(\.trustStatsManager, trustStatsManager)
              .environment(\.friendManager, friendManager)
              .environmentObject(deepLink)
              .environmentObject(modal)
              .overlay {
                GlobalModalHost()
                  .environmentObject(modal)
                  .environmentObject(deepLink)
              }
              .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                  NotificationManager.shared.recoverDeliveredPushes()
                }
              }
        }
    }
}

// MARK: - AppDelegate

class AppDelegate: NSObject, UIApplicationDelegate {
  
  /// configure notification & location
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
    NotificationManager.shared.configure()
    LocationManager.shared.requestAuthorization()
    
    Task { @MainActor in
      NotificationManager.shared.registerForAPNs()
    }
    
    #if DEBUG
    NotificationManager.shared.debug_dumpSilentEnvironment()
    #endif
    
    return true
  }
  
  // MARK: for Remote Notifications
  
  func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    NotificationManager.shared.didRegister(deviceToken: deviceToken)
  }
  
  func application(
    _ application: UIApplication, 
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    NotificationManager.shared.didFailToRegister(error: error)
  }
  
  /// Silent Notification Handler
  func application(_ application: UIApplication,
                   didReceiveRemoteNotification userInfo: [AnyHashable : Any],
                   fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    NotificationManager.shared.handleSilentWake(userInfo: userInfo, completion: completionHandler)
  }
}
