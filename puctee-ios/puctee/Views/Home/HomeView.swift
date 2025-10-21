//
//  HomeView.swift
//  puctee
//
//  Created by kj on 5/9/25.
//

import SwiftUI
import CoreLocation

struct HomeView: View {
  @State private var showCreatePlanSheet = false
  @State private var showSidebar = false
  @State private var showCelebrateModal = false
  @State private var showLocationPermissionModal = false
  
  @Environment(\.planManager) private var planManager
  @Environment(\.friendManager) private var friendManager
  @Environment(\.trustStatsManager) private var trustStatsManager
  @Environment(\.accountManager) private var accountManager
  @Environment(\.colorScheme) private var colorScheme
  
  @ObservedObject private var locationManager = LocationManager.shared
  
  // load data automatically only when homeview appears for the first time
  @State private var didAutoLoadOnAppear = false
  
  // Track if user has ever granted Always permission
  @AppStorage("hasGrantedAlwaysPermission") private var hasGrantedAlwaysPermission = false
  
  // Track if modal was dismissed in current session (reset on app restart)
  @State private var dismissedInCurrentSession = false
  
  var body: some View {
    NavigationStack {
      ZStack(alignment: .bottomTrailing) {
        VStack {
          HomeHeader(showSidebar: $showSidebar)
          ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
              HomeTrustStatsCardView()
              HomePlanListTabView()
            }
            .padding(.vertical)
          }
          .refreshable {
            await load()
          }
        }
        .disabled(showSidebar || showCelebrateModal)
        .offset(x: showSidebar ? UIScreen.main.bounds.width * 0.6 : 0)
        
        HomeCreatePlanButton {
          showCreatePlanSheet.toggle()
        }
        .padding(.bottom, 8)
        .padding(.trailing, 24)
        .offset(x: showSidebar ? UIScreen.main.bounds.width * 0.6 : 0)
        .disabled(showSidebar || showCelebrateModal)
        
        if showSidebar {
          Color.black.opacity(0.4)
            .ignoresSafeArea()
            .onTapGesture {
              withAnimation(.easeInOut) {
                showSidebar = false
              }
            }
        }
        
        HomeSideBarMenu()
          .frame(width: UIScreen.main.bounds.width * 0.6)
          .background(colorScheme == .dark ? Color.black : Color.white)
          .offset(x: showSidebar ? -UIScreen.main.bounds.width * 0.4 : -UIScreen.main.bounds.width)
          .animation(.easeInOut, value: showSidebar)
        
        // MARK: Show modals
        if showCelebrateModal {
          CelebratePlanCreationModal(isPresented: $showCelebrateModal)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .zIndex(1)
        }
        
        if showLocationPermissionModal {
          LocationAlwaysPermissionModal(isPresented: $showLocationPermissionModal)
            .transition(.opacity)
            .zIndex(2)
        }
      }
      .background(Color(.systemGroupedBackground).ignoresSafeArea())
      .navigationBarHidden(true)
      .task {
        guard !didAutoLoadOnAppear else { return }
        didAutoLoadOnAppear = true
        await load()
      }
      .onChange(of: accountManager.isAuthenticated) { _, isAuthed in
        if !isAuthed { didAutoLoadOnAppear = false }
      }
      .onChange(of: locationManager.authorizationStatus) { _, newStatus in
        // Track if user granted Always permission
        if newStatus == .authorizedAlways {
          hasGrantedAlwaysPermission = true
        }
        checkLocationPermission(status: newStatus)
      }
      .onAppear {
        checkLocationPermission(status: locationManager.authorizationStatus)
      }
      .onChange(of: showLocationPermissionModal) { _, isShowing in
        if !isShowing {
          dismissedInCurrentSession = true
        }
      }
    }
    .sheet(isPresented: $showCreatePlanSheet) {
      PlanEditorView {
        // Called by PlanEditorView when a NEW plan is created
        showCreatePlanSheet = false
        // slight delay to make dismissal feel smooth before showing celebration
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          withAnimation(.easeInOut) {
            showCelebrateModal = true
          }
        }
      }
    }
  }
  
  private func load() async {
    await planManager.fetchPlans(by: [.upcoming, .cancelled, .completed, .ongoing])
    await planManager.fetchInvites()
    await friendManager.fetchReceivedInvites()
    await trustStatsManager.fetchTrustStats()
  }
  
  private func checkLocationPermission(status: CLAuthorizationStatus) {
    // Show modal if:
    // 1. User has WhenInUse permission (not Always)
    // 2. User hasn't dismissed modal in current session
    // 3. User previously had Always permission but downgraded (hasGrantedAlwaysPermission is true but current status is not Always)
    //    OR user never had Always permission
    
    // Don't show if already dismissed in this session
    guard !dismissedInCurrentSession else { return }
    
    switch status {
    case .authorizedWhenInUse:
      // User has WhenInUse but not Always
      // Show modal if they never had Always, or if they downgraded from Always
      withAnimation {
        showLocationPermissionModal = true
      }
    case .authorizedAlways:
      // Already has Always permission - no need to show
      break
    case .notDetermined, .denied, .restricted:
      // Don't show modal for these states
      break
    @unknown default:
      break
    }
  }
}

#Preview {
  HomeView()
}
