//
//  PlanListCellView.swift
//  puctee
//
//  Created by kj on 5/9/25.
//

import SwiftUI

struct PlanListCellView: View {
  let plan: Plan
  
  private var shouldHighlight: Bool {
    plan.status == .ongoing
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      header
      dateInfo
      locationAndParticipants
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(
          shouldHighlight
          ? AnyShapeStyle(
            LinearGradient(
              colors: [
                Color.red.opacity(0.9),
                Color.orange.opacity(0.8)
              ],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
          : AnyShapeStyle(.regularMaterial)
        )
    )
    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    .padding(.horizontal)
  }
  
  private var header: some View {
    HStack {
      Text(plan.title)
        .font(.headline)
        .foregroundColor(shouldHighlight ? .white : .primary)
      
      Spacer()
      
      Image(systemName: "chevron.right")
        .font(.caption2)
        .foregroundColor(shouldHighlight ? .white.opacity(0.8) : .secondary)
    }
  }
  
  private var dateInfo: some View {
    Text(formattedDateText(from: plan.startTime))
      .font(.subheadline)
      .foregroundColor(shouldHighlight ? .white.opacity(0.9) : .secondary)
  }
  
  private var locationAndParticipants: some View {
    HStack {
      Label(plan.location.name, systemImage: "mappin.and.ellipse")
        .font(.subheadline)
        .foregroundColor(shouldHighlight ? .white.opacity(0.9) : .secondary)
      
      Spacer()
      
      ParticipantsStackView(for: plan.participants)
    }
  }
}


#Preview {
  PlanListCellView(plan: SampleData.planKickoff)
  PlanListCellView(plan: SampleData.planPicnic)
}
