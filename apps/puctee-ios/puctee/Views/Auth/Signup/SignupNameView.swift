//
//  SignupNameView.swift
//  puctee
//
//  Created by kj on 5/8/25.
//

import SwiftUI

struct SignupNameView: View {
  @Binding var name: String
  var onNext: () -> Void
  @FocusState private var isFocused: Bool
  
  var body: some View {
    VStack(spacing: 40) {
      Spacer()
      
      Text("Welcome to puctee!\nPlease tell us your name")
        .multilineTextAlignment(.center)
        .font(.title3)
        .fontWeight(.bold)
    
      // Input field
      HStack {
        TextField("Name", text: $name)
          .focused($isFocused)
          .autocorrectionDisabled()
          .textInputAutocapitalization(.words)
      }
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 12)
          .stroke(
            isFocused
            ? Color.accentColor
            : Color.secondary.opacity(0.3),
            lineWidth: 1
          )
      )
      
      // Next button
      Button(action: onNext) {
        Text("Next")
          .frame(width: 200)
      }
      .buttonStyle(.borderedProminent)
      .controlSize(.large)
      .disabled(name.isEmpty)
      .opacity(name.isEmpty ? 0.6 : 1.0)
      
      Spacer()
    }
    .padding(.horizontal, 24)
  }
}

struct SignupNameView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      SignupNameView(name: .constant(""), onNext: {})
    }
    .preferredColorScheme(.light)
    
    NavigationStack {
      SignupNameView(name: .constant("Kojiro"), onNext: {})
    }
    .preferredColorScheme(.dark)
  }
}
