//
//  PlanEditorPenaltySection.swift
//  puctee
//
//  Created by kj on 5/15/25.
//

import SwiftUI

struct PlanEditorPenaltySection: View {
  @Bindable var vm: PlanEditorViewModel
  @FocusState private var isTextFieldFocused: Bool
  
  @State private var isAdding: Bool = false
  
  var body: some View {
    VStack(spacing: 12) {
      if isAdding || !vm.penaltyText.isEmpty {
        HStack(spacing: 12) {
          Image(systemName: "clock.badge.exclamationmark.fill")
            .foregroundColor(.gray)
          
          TextField("Enter penalty details...", text: $vm.penaltyText)
            .focused($isTextFieldFocused)
            .submitLabel(.done)
            .onSubmit {
              if vm.penaltyText.isEmpty {
                isAdding = false
              }
            }
          
          // Close button
          Button {
            vm.penaltyText = ""
            isAdding = false
          } label: {
            Image(systemName: "xmark.circle.fill")
              .font(.title3)
              .foregroundColor(.secondary)
          }
          .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .frame(height: 44)
        .background(.thinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .onAppear {
          if vm.penaltyText.isEmpty {
            isTextFieldFocused = true
          }
        }
      } else {
        Button {
          isAdding = true
        } label: {
          HStack {
            Image(systemName: "plus.circle.fill")
              .font(.title2)
            Text("Add Penalty")
              .font(.subheadline.weight(.semibold))
            Spacer()
          }
          .foregroundStyle(.primary)
          .padding(.horizontal)
          .frame(height: 44)
          .background(.thinMaterial)
          .cornerRadius(16)
          .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
      }
    }
    .padding(.vertical, 8)
  }
}
