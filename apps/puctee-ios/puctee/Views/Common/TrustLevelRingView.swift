//
//  TrustLevelCircleChart.swift
//  puctee
//
//  Created by kj on 6/7/25.
//

import SwiftUI

// 数字をなめらかにカウントアップ/ダウンさせるための Modifier
private struct CountingText: AnimatableModifier {
  var value: Double
  var format: String = "%.0f"
  var color: Color
  
  var animatableData: Double {
    get { value }
    set { value = newValue }
  }
  func body(content: Content) -> some View {
    Text(String(format: format, value))
      .font(.title2).bold()
      .foregroundColor(color)
  }
}

struct TrustLevelRingView: View {
  /// 0.0〜100.0 の目標値（これが変化したらアニメさせる）
  var trustLevel: Double
  var lineWidth: CGFloat = 14
  var animationDuration: Double = 0.6
  
  @State private var displayedProgress: Double = 0.0     // 0.0〜1.0 の表示用
  @State private var displayedLevel: Double = 0.0        // 0.0〜100.0 の表示用
  
  private var targetProgress: Double { min(max(trustLevel/100.0, 0), 1) }
  
  private var ringColor: Color {
    switch trustLevel {
      case 0..<25:   return .red
      case 25..<50:  return .yellow
      case 50..<75:  return .blue
      case 75..<90:  return .green
      default:       return .orange
    }
  }
  
  var body: some View {
    ZStack {
      Circle().stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)
      
      Circle()
        .trim(from: 0, to: displayedProgress)
        .stroke(ringColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        .rotationEffect(.degrees(-90))
      
      HStack(alignment: .firstTextBaseline, spacing: 4) {
        // 中央の数値もなめらかに遷移
        Text("") // ダミー（CountingTextを乗せるための container）
          .modifier(CountingText(value: displayedLevel, color: ringColor))
        Text("%")
          .font(.caption).bold().foregroundColor(ringColor).baselineOffset(2)
      }
    }
    .onAppear {
      // 初期表示時：0→目標へアニメ
      displayedProgress = 0
      displayedLevel = 0
      withAnimation(.easeOut(duration: animationDuration)) {
        displayedProgress = targetProgress
        displayedLevel = trustLevel
      }
    }
    .onChange(of: trustLevel) { _, newValue in
      // 値が変わったとき：現在表示値→新しい目標へアニメ
      let newProgress = min(max(newValue/100.0, 0), 1)
      withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
        displayedProgress = newProgress
        displayedLevel = newValue
      }
    }
  }
}

#Preview() {
  Group {
    TrustLevelRingView(trustLevel: 4)
      .frame(width: 100, height: 100)
    TrustLevelRingView(trustLevel: 26)
      .frame(width: 100, height: 100)
    TrustLevelRingView(trustLevel: 53)
      .frame(width: 100, height: 100)
    TrustLevelRingView(trustLevel: 77)
      .frame(width: 100, height: 100)
    TrustLevelRingView(trustLevel: 95)
      .frame(width: 100, height: 100)
  }
  .padding()
}
