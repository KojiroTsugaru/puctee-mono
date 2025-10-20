//
//  GlobalModalHost.swift
//  puctee
//
//  Created by kj on 8/21/25.
//

import SwiftUI

struct GlobalModalHost: View {
  @EnvironmentObject var modal: ModalCoordinator
  
  var body: some View {
    ZStack {
      if let route = modal.current {
        switch route {
          case .arrival:
            ArrivalPagerView(isPresented: bindingToDismiss())
              .transition(.move(edge: .bottom).combined(with: .opacity))
              .zIndex(1002)
          case let .penaltyApprovalRequest(requestId: requestId):
            PenaltyApprovalModal(approvalRequestId: requestId, isPresented: bindingToDismiss())
              .transition(.move(edge: .bottom).combined(with: .opacity))
              .zIndex(1003)
        }
      }
    }
    .ignoresSafeArea()
    .animation(.easeInOut, value: modal.current != nil)
    .allowsHitTesting(modal.current != nil)
  }
  
  private func bindingToDismiss() -> Binding<Bool> {
    Binding(
      get: { modal.current != nil },
      set: { if $0 == false { modal.dismissCurrent() } }
    )
  }
}

// Plan をIDから取得して本番Viewへ受け渡す例（必要なら）
struct PenaltyApprovalWrapper: View {
  let planId: Int
  let userId: Int
  @Binding var isPresented: Bool
  
  @State private var plan: Plan?
  @State private var isLoading = true
  
  var body: some View {
    Group {
      if isLoading {
        ProgressView().padding().background(.ultraThinMaterial).clipShape(RoundedRectangle(cornerRadius: 16))
      } else {
        PlanPenaltyApprovalRequestView(plan: plan, isPresented: $isPresented)
      }
    }
    .task {
      await load()
    }
  }
  
  private func load() async {
    do {
      // 実アプリの取得に置き換え
      self.plan = try? await PlanService.shared.fetchPlan(id: planId)
    }
    self.isLoading = false
  }
}
