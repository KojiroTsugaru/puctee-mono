//
//  HomeCreatePlanButton.swift
//  puctee
//
//  Created by kj on 5/9/25.
//

import SwiftUI

struct HomeCreatePlanButton: View {
  // A closure can be passed to handle the action when pressed
  var action: () -> Void = {}
  
  var body: some View {
    Button(action: action) {
      Image(systemName: "plus")
        .font(.system(size: 28, weight: .bold))
        .foregroundColor(.white)
        .frame(width: 60, height: 60)
        .background(
          Circle()
            .fill(Color.accentColor)
        )
    }
    .buttonStyle(PlainButtonStyle())
  }
}

struct HomeCreatePlanButton_Previews: PreviewProvider {
  static var previews: some View {
    HomeCreatePlanButton {
      print("The + button was tapped")
    }
    .previewLayout(.sizeThatFits)
    .padding()
  }
}
