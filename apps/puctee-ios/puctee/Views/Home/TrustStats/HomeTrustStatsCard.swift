//
//  HomeTrustChart.swift
//  puctee
//
//  Created by kj on 5/9/25.
//

import SwiftUI

// MARK: - Container for the entire card
struct HomeTrustStatsCardView: View {
  @Environment(\.trustStatsManager) private var trustStatsManager
  
  private var latenessPercentage: Float {
    guard let stats = trustStatsManager.trustStats,
          stats.totalPlans > 0 else { return 0 }
    return (Float(stats.latePlans) / Float(stats.totalPlans)) * 100
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      // Header
      HStack {
        Text("Your Trust Level")
          .font(.title3).fontWeight(.semibold)
        Spacer()
        Button(action: shareAction) {
          Image(systemName: "square.and.arrow.up")
            .font(.body)
            .foregroundColor(.secondary)
        }
      }
      
      // Content: numbers on the left, chart on the right
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 12) {
          HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("🔥")
              .font(.subheadline)
            Text("Streak")
              .font(.subheadline)
              .foregroundColor(.secondary)
            Text("\(String(describing: trustStatsManager.trustStats?.onTimeStreak ?? 0))")
              .font(.title2)
              .fontWeight(.bold)
              .padding(.horizontal)
          }
          
          HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("🎯")
              .font(.subheadline)
            Text("On-Time")
              .font(.subheadline)
              .foregroundColor(.secondary)
            Text(String(format: "%.1f%%", latenessPercentage))
              .font(.title2)
              .fontWeight(.bold)
              .padding(.horizontal, 4)
          }
        }
        
        Spacer()
        
        TrustLevelRingView(
          trustLevel: trustStatsManager.trustStats?.trustLevel ?? 0
        )
        .frame(width: 100, height: 100)
        .padding(.trailing)
        .id(trustStatsManager.trustStats?.trustLevel ?? 0)
      }
    }
    .padding(20)
    // Material background + rounded corners + shadow
    .background(.regularMaterial, in:
                  RoundedRectangle(cornerRadius: 16, style: .continuous)
    )
    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    .padding(.horizontal, 16)
  }
  
  private func shareAction() {
    // Logic to show share sheet, etc.
  }
}

struct HomeTrustCardView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      HomeTrustStatsCardView()
        .preferredColorScheme(.light)
      HomeTrustStatsCardView()
        .preferredColorScheme(.dark)
    }
  }
}
