//
//  TrustStatsPage.swift
//  puctee
//
//  Created by kj on 8/19/25.
//

import SwiftUI

public struct ArrivalTrustStatsPage: View {
  var onBack: () -> Void
  var onDone: () -> Void
  let prevLevel: Double
  let newLevel: Double
  
  @State private var currentLevel: Double
  @State private var delta: Double? = nil
  @State private var isLoading = true
  @State private var error: String?
  
  @EnvironmentObject private var deepLink: DeepLinkHandler
  @Environment(\.trustStatsManager) private var trustStatsManager
  
  public init(prevLevel: Double,
              newLevel: Double,
              onBack: @escaping () -> Void,
              onDone: @escaping () -> Void) {
    self.onBack = onBack
    self.onDone = onDone
    self.prevLevel = prevLevel
    self.newLevel = newLevel
    self._currentLevel = State(initialValue: prevLevel)
  }
  
  public var body: some View {
    VStack(spacing: 16) {
      Text("Trust Progress").font(.headline)
      
      // リング（前値→新値にアニメ）
      TrustLevelRingView(trustLevel: currentLevel)
        .frame(width: 120, height: 120)
        .padding(.top, 4)
      
      // 差分チップ
      if let d = delta {
        HStack(spacing: 8) {
          let up = d >= 0
          Image(systemName: up ? "arrow.up.right" : "arrow.down.right")
          Text("\(up ? "+" : "−")\(String(format: "%.0f", abs(d))) pts")
        }
        .font(.subheadline.bold())
        .foregroundStyle(d >= 0 ? .green : .red)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background((d >= 0 ? Color.green.opacity(0.12) : Color.red.opacity(0.12)),
                    in: Capsule())
        .transition(.opacity.combined(with: .scale))
      }
      
      // ローディング/エラー
      if isLoading {
        ProgressView("Fetching your trust stats…").padding(.top, 8)
      } else if let error {
        VStack(spacing: 8) {
          Text("Failed to load trust stats").foregroundColor(.secondary)
          Text(error).font(.caption).foregroundColor(.secondary)
          Button("Retry") { Task { await load() } }
            .buttonStyle(CapsuleFillButtonStyle(.gray))
        }
      }
      
      Spacer(minLength: 0)
      
      // フッターボタン（ArrivalResultと統一のカプセル＋グラデ）
      HStack(spacing: 12) {
        Button {
          onBack()
        } label: {
          Text("Back")
        }
        .buttonStyle(CapsuleFillButtonStyle(.gray))
        
        Button {
          onDone()
          deepLink.consume()
        } label: {
          Text("Done")
        }
        .buttonStyle(CapsuleFillButtonStyle(.green))
      }
      .padding(.top, 8)
    }
    .padding(.horizontal)
    .padding(.top, 12)
    .task { await load() }
  }
  
  // TrustStatsManager を用いたフェッチ → 差分アニメ
  private func load() async {
    isLoading = true
    error = nil
    
    // Calculate delta immediately since we have both values
    delta = newLevel - prevLevel
    
    // Animate to new level
    withAnimation(.spring(response: 0.6, dampingFraction: 0.9)) {
      currentLevel = newLevel
    }
    
    // Haptic feedback for positive changes
    if (delta ?? 0) > 0 {
      let gen = UINotificationFeedbackGenerator()
      gen.notificationOccurred(.success)
    }
    
    // Optional: Still fetch trust stats if needed for other data
    await trustStatsManager.fetchTrustStats()
    
    isLoading = false
  }
}
