//
//  PlanEditorTitleTextfield.swift
//  puctee
//
//  Created by kj on 5/16/25.
//

import SwiftUI

struct PlanEditorTitleTextfield: View {
  @Binding var vm: PlanEditorViewModel
  
  var body: some View {
    UnderlinedTextField("Enter plan title", text: $vm.titleText)
    if let err = vm.titleError {
      Text(err)
        .font(.caption)
        .foregroundColor(.red)
    }
  }
}
