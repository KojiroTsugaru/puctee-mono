//
//  PlanEditorTimeSection.swift
//  puctee
//
//  Created by kj on 5/10/25.
//

import SwiftUI

struct PlanEditorTimeSection: View {
  @Binding var vm: PlanEditorViewModel
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Label("Time", systemImage: "clock")
        .foregroundStyle(.gray)
      
//      CustomTimePicker(date: $vm.startTime)
//        .background(Color(UIColor.systemBackground))
//        .cornerRadius(12)
//        .shadow(radius: 2, y: 1)
      DatePicker(
        "",
        selection: $vm.startTime,
        displayedComponents: .hourAndMinute
      )
      .datePickerStyle(.compact)
      .labelsHidden()
      .font(.system(size: 24, weight: .medium)) 
      if let err = vm.dateError {
        Text(err)
          .font(.caption)
          .foregroundColor(.red)
      }
    }
  }
}
