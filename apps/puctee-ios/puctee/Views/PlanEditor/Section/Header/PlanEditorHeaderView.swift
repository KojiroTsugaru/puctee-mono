//
//  PlanEditorHeaderView .swift
//  puctee
//
//  Created by kj on 5/10/25.
//

import SwiftUI

struct PlanEditorHeaderView: View {
  let onCreate: () -> Void
  
  @Environment(\.dismiss) private var dismiss
  @Environment(\.planManager) var planManager
  @Binding var vm: PlanEditorViewModel
  
  private var isEditMode: Bool {
    vm.planId != nil
  }
  
  private var titleText: String {
    isEditMode ? "Edit Plan" : "Create Plan"
  }
  
  private var buttonText: String {
    isEditMode ? "Save" : "Create"
  }
  
  var body: some View {
    ZStack(alignment: .center) {
      HStack {
        Button { dismiss() } label: {
          Image(systemName: "xmark")
            .foregroundColor(.accent)
        }
        Spacer()
        Button {
          Task {
            if isEditMode {
              await vm.savePlan(using: planManager) {
                dismiss()
              }
            } else {
              await vm.createPlan(using: planManager) {
                onCreate()
              }
            }
          }
        } label: {
          Text(buttonText)
            .font(.subheadline).bold()
            .padding(.vertical, 8).padding(.horizontal, 16)
            .background(.accent)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .disabled(vm.isLoading)
      }
      Text(titleText)
        .font(.headline)
    }.padding(.top)
  }
}
