//
//  TrustStatsPage.swift
//  puctee
//
//  Created by kj on 8/19/25.
//

import SwiftUI

public struct ArrivalTrustStatsPage: View {
  var previousLevel: Double?
  var onBack: () -> Void
  var onDone: () -> Void
  
  @State private var currentLevel: Double = 0
  @State private var delta: Double? = nil
  @State private var isLoading = true
  @State private var error: String?
  
  @EnvironmentObject private var deepLink: DeepLinkHandler
  @Environment(\.trustStatsManager) private var trustStatsManager
  
  public init(previousLevel: Double? = 0,
              onBack: @escaping () -> Void,
              onDone: @escaping () -> Void) {
    self.previousLevel = previousLevel
    self.onBack = onBack
    self.onDone = onDone
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
    .task { await setupAndLoad() }
  }
  
  // 初期セット → フェッチ
  private func setupAndLoad() async {
    currentLevel = previousLevel ?? 0
    await load()
  }
  
  // TrustStatsManager を用いたフェッチ → 差分アニメ
  private func load() async {
    isLoading = true
    error = nil
    await trustStatsManager.fetchTrustStats()
    
    guard let stats = trustStatsManager.trustStats else {
      isLoading = false
      error = "No data"
      return
    }
    
    // ← あなたの TrustStats に合わせて（例: trustLevel が 0...100）
    let newLevel = stats.trustLevel
    
    let old = currentLevel
    delta = newLevel - old
    
    withAnimation(.spring(response: 0.6, dampingFraction: 0.9)) {
      currentLevel = newLevel
    }
    
    // （任意）良い変化ならハプティクス
    if (delta ?? 0) > 0 {
      let gen = UINotificationFeedbackGenerator()
      gen.notificationOccurred(.success)
    }
    
    isLoading = false
  }
}
