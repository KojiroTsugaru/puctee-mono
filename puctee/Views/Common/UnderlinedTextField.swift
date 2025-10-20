//
//  UnderlinedTextField.swift
//  puctee
//
//  Created by kj on 5/10/25.
//

import SwiftUI

/// TextField with an underline whose length matches the current text (or placeholder).
/// Works inside HStack/VStack regardless of surrounding views.
struct UnderlinedTextField: View {
  private let placeholder: String
  @Binding private var text: String
  private var font: UIFont
  private var underlinePadding: CGFloat
  private var underlineColor: Color
  
  /// - Parameters:
  ///   - placeholder: Placeholder text when empty.
  ///   - text: Two‑way binding for the field value.
  ///   - font: UIFont used to measure text. Default: `.preferredFont(forTextStyle: .title2)`
  ///   - underlinePadding: Extra points added to the calculated width.
  ///   - underlineColor: Color of the underline. Default: `.primary` with 50 % opacity.
  init(_ placeholder: String,
       text: Binding<String>,
       font: UIFont = .preferredFont(forTextStyle: .title2),
       underlinePadding: CGFloat = 8,
       underlineColor: Color = .primary) {
    self.placeholder = placeholder
    self._text = text
    self.font = font
    self.underlinePadding = underlinePadding
    self.underlineColor = underlineColor.opacity(0.1)
  }
  
  var body: some View {
    ZStack(alignment: .leading) {
      // TextField itself
      TextField(placeholder, text: $text)
        .font(Font(font))
        .padding(.vertical, 8)
    }
    // Draw underline at the bottom *inside* the ZStack so its width calculation
    // is unaffected by neighbouring views in an HStack.
    .overlay(alignment: .bottomLeading) {
      Rectangle()
        .fill(underlineColor)
        .frame(width: underlineWidth + underlinePadding, height: 1.2)
    }
  }
  
  // MARK: – Helpers
  private var underlineWidth: CGFloat {
    let display = text.isEmpty ? placeholder : text
    let size = (display as NSString).size(withAttributes: [.font: font])
    return size.width
  }
}
