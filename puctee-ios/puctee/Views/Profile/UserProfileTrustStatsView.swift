//
//  UserProfileTrustStatsView.swift
//  puctee
//
//  Created by kj on 6/9/25.
//

import SwiftUI

// MARK: - Container for the entire card
struct UserProfileTrustStatsView: View {
  let user: User?
  
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
        Text("Trust Level")
          .font(.title3).fontWeight(.semibold)
        Spacer()
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
            Text("Lateness Rate")
              .font(.subheadline)
              .foregroundColor(.secondary)
            Text(String(format: "%.1f%%", latenessPercentage))
              .font(.title2)
              .fontWeight(.bold)
              .padding(.horizontal)
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
    .padding(.horizontal, 20)
    .task {
      await trustStatsManager.fetchTrustStats()
    }
  }
  
  private func shareAction() {
    // Logic to show share sheet, etc.
  }
}

struct UserProfileTrustStatsView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      UserProfileTrustStatsView(user: SampleData.alice)
        .preferredColorScheme(.light)
      UserProfileTrustStatsView(user: SampleData.alice)
        .preferredColorScheme(.dark)
    }
  }
}
