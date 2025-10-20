//
//  ArrivalPagerView.swift
//  puctee
//
//  Created by kj on 8/19/25.
//

import SwiftUI

struct ArrivalPagerView: View {
  @Binding var isPresented: Bool
  
  private enum Step { case result, trustStats }
  @State private var step: Step = .result
  
  @Environment(\.trustStatsManager) private var trustStatsManager
  
  var body: some View {
    GeometryReader { proxy in
      ZStack {
        Color.black.opacity(0.2).ignoresSafeArea()
        
        ZStack {
          switch step {
            case .result:
              ArrivalResultPage {
                withAnimation(.easeInOut) { step = .trustStats }
              }
              .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal:   .move(edge: .leading).combined(with: .opacity)
              ))
              
            case .trustStats:
              ArrivalTrustStatsPage(
                previousLevel: trustStatsManager.trustStats?.trustLevel,
                onBack: {
                  withAnimation(.easeInOut) { step = .result }
                },
                onDone: {
                  withAnimation(.easeInOut) { isPresented = false }
                }
              )
              .transition(.asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal:   .move(edge: .trailing).combined(with: .opacity)
              ))
          }
        }
        .animation(.easeInOut, value: step)
        .frame(height: proxy.size.height * 0.4)
        .frame(maxWidth: .infinity)
        .padding()
        .background(
          RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color(.systemBackground))
            .shadow(color: .black.opacity(0.1), radius: 16, x: 0, y: 8)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal, 16)
        .transition(.move(edge: .bottom).combined(with: .opacity))
      }
    }
  }
}

