//
//  ShowArrivalModal.swift
//  puctee
//
//  Created by kj on 5/20/25.
//

import SwiftUI

struct ArrivalResultPage: View {
  @EnvironmentObject private var deepLink: DeepLinkHandler
  var onNext: () -> Void
  
  // deepLink から動的に取得（pendingArrivalResult が Optional の場合は適宜デフォルト）
  private var isArrived: Bool {
    deepLink.pendingArrivalResult ?? true
  }
  
  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: isArrived ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
        .font(.system(size: 60))
        .foregroundStyle(isArrived ? .green : .yellow)
      
      Text(isArrived ? "You've arrived on time!" : "Could not arrive in time…")
        .font(.title)
        .fontWeight(.bold)
        .multilineTextAlignment(.center)
        .padding(.bottom, 12)
      
      Text(isArrived
           ? "Your friends can count on you\nkeep it up 🔥"
           : "Let's leave with more time next time")
      .font(.body)
      .foregroundColor(.secondary)
      .multilineTextAlignment(.center)
      .padding(.horizontal)
      .padding(.bottom, 40)
      
      // TODO: Notify about the increase/decrease in trust level here
      
      Button {
        onNext()
      } label: {
        Text("Next")
      }
      .buttonStyle(CapsuleFillButtonStyle(.green))
    }
  }
}

struct ArrivalStatusModal_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      ArrivalResultPage(onNext: {})
      ArrivalResultPage(onNext: {})
    }
    .previewLayout(.sizeThatFits)
  }
}
