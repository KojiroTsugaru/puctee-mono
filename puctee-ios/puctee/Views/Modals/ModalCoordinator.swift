//
//  ModalCoordinator =.swift
//  puctee
//
//  Created by kj on 8/21/25.
//

import SwiftUI
import Combine

final class ModalCoordinator: ObservableObject {
  static let shared = ModalCoordinator()
  
  @Published private(set) var current: ModalRoute? = nil
  
  private var queue: [ModalRoute] = []
  private var cancellables = Set<AnyCancellable>()
  
  private init(deepLink: DeepLinkHandler = .shared) {
    // DeepLink の変化を監視 → Route を生成して投入
    Publishers.CombineLatest(
      Publishers.CombineLatest3(deepLink.$pendingPlanId,
                                deepLink.$pendingArrivalResult,
                                deepLink.$pendingPenaltyRequestId),
      Publishers.CombineLatest(deepLink.$pendingPrevTrustLevel,
                               deepLink.$pendingNewTrustLevel)
    )
    .receive(on: DispatchQueue.main)
    .sink { [weak self] basicInfo, trustLevels in
      guard let self else { return }
      
      let (pid, arrived, requestId) = basicInfo
      let (prevTrust, newTrust) = trustLevels
      
      let incoming: ModalRoute
      if let requestId = requestId {
        incoming = .penaltyApprovalRequest(requestId: requestId)
      } else if let pid = pid, let arrived = arrived {
        incoming = .arrival(planId: pid, isArrived: arrived, prevTrustLevel: prevTrust, newTrustLevel: newTrust)
      } else {
        return
      }
      self.enqueue(incoming)
    }
    .store(in: &cancellables)
  }
  
  func enqueue(_ route: ModalRoute) {
    // 置き換え優先（Penalty が来たら Arrival を即置換したい場合）
    if let cur = current, route.priority > cur.priority {
      withAnimation(.easeInOut) { current = route }
      return
    }
    
    // 何も表示していない → すぐ出す
    guard current != nil else {
      withAnimation(.easeInOut) { current = route }
      return
    }
    
    // それ以外はキューへ
    queue.append(route)
  }
  
  func dismissCurrent() {
    DeepLinkHandler.shared.consume() // DeepLink 状態をクリア
    if queue.isEmpty {
      withAnimation(.easeInOut) { current = nil }
    } else {
      let next = queue.removeFirst()
      withAnimation(.easeInOut) { current = next }
    }
  }
}

