//
//  CapsuleFillButtonStyle.swift
//  puctee
//
//  Created by kj on 8/19/25.
//

import SwiftUI

struct CapsuleFillButtonStyle: ButtonStyle {
  enum Style {
    case green
    case accent
    case gray
    case red
  }
  
  var style: Style = .accent
  
  init(_ style: Style = .accent) {
    self.style = style
  }
  
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.subheadline.bold())
      .frame(maxWidth: .infinity)
      .padding(.vertical, 12)
      .background(
        LinearGradient(
          gradient: gradient(for: style),
          startPoint: .top,
          endPoint: .bottom
        )
        .opacity(configuration.isPressed ? 0.85 : 1.0)
      )
      .foregroundColor(.white)
      .clipShape(Capsule())
      .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
      .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
      .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
  }
  
  private func gradient(for style: Style) -> Gradient {
    switch style {
      case .green:
        return Gradient(colors: [Color.green, Color.green.opacity(0.8)])
      case .accent:
        return Gradient(colors: [Color.accentColor, Color.accentColor.opacity(0.8)])
      case .gray:
        return Gradient(colors: [Color.gray, Color.gray.opacity(0.8)])
      case .red:
        return Gradient(colors: [Color(.systemRed), Color(.systemRed).opacity(0.8)])
    }
  }
}

