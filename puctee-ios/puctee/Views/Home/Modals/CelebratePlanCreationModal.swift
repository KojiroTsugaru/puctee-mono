//
//  CelebrateOverlay.swift
//  puctee
//
//  Created by kj on 5/19/25.
//

import SwiftUI

struct CelebratePlanCreationModal: View {
  @Binding var isPresented: Bool
  // TODO: Re-enable when invite link functionality is ready
  // @State private var shareURL: String = "https://puctee.app/plan/12345"
  // @State private var copied: Bool = false
  
  var body: some View {
    ZStack {
      Color(.black).opacity(0.2)
        .ignoresSafeArea(.all)
      
      VStack(spacing: 24) {
        Spacer()
        
        // 🎉 Success icon
        Image(systemName: "checkmark.seal.fill")
          .resizable()
          .scaledToFit()
          .frame(width: 64, height: 64)
          .foregroundStyle(
            LinearGradient(
              gradient: Gradient(colors: [Color.blue, Color.purple]),
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )
        
        // Success message
        Text("The plan has been created")
          .font(.title2)
          .fontWeight(.semibold)
        
        // Subtitle
        Text("You're all set to start working on your goal!")
          .font(.subheadline)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
        
        // TODO: Re-enable when invite link functionality is ready
        // Share link section
        // HStack(spacing: 8) {
        //   Image(systemName: "link")
        //     .foregroundColor(.secondary)
        //   Text(shareURL)
        //     .font(.footnote)
        //     .lineLimit(1)
        //     .truncationMode(.middle)
        //     .foregroundColor(.blue)
        //     .onTapGesture(perform: copyLink)
        //   Spacer()
        //   Button(action: copyLink) {
        //     Image(systemName: "doc.on.doc")
        //       .foregroundColor(.primary)
        //   }
        //   .buttonStyle(.plain)
        // }
        // .padding(12)
        // .background(.thinMaterial)
        // .cornerRadius(10)
        // .contextMenu {
        //   Button("Copy link") { copyLink() }
        // }
        
        // Close button
        Button {
          withAnimation(.easeInOut) {
            isPresented = false
          }
        } label: {
          Text("Close")
            .font(.subheadline.bold())
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
              LinearGradient(
                gradient: Gradient(colors: [Color.green, Color.green.opacity(0.8)]),
                startPoint: .top,
                endPoint: .bottom
              )
            )
            .foregroundColor(.white)
            .clipShape(Capsule())
        }
        .buttonStyle(PlainButtonStyle())
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.bottom)
      }
      .padding()
      .frame(height: UIScreen.main.bounds.height * 0.4)
      .background(Color(.systemBackground))
      .cornerRadius(20)
      .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
      .padding(.horizontal, 24)
      // TODO: Re-enable when invite link functionality is ready
      // Copy complete alert
      // .alert("Link copied", isPresented: $copied) {
      //   Button("OK", role: .cancel) {}
      // }
    }
  }
  
  // TODO: Re-enable when invite link functionality is ready
  // private func copyLink() {
  //   UIPasteboard.general.string = shareURL
  //   withAnimation { copied = true }
  // }
}

struct CelebrateOverlay_Previews: PreviewProvider {
  static var previews: some View {
    CelebratePlanCreationModal(isPresented: Binding.constant(true))
      .preferredColorScheme(.light)
    CelebratePlanCreationModal(isPresented: Binding.constant(true))
      .preferredColorScheme(.dark)
  }
}

