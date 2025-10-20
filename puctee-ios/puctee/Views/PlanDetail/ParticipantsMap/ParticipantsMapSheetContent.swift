//
//  ParticipantsMapSheetContent.swift
//  puctee
//
//  Created by kj on 7/2/25.
//

import SwiftUI
import Kingfisher

struct ParticipantsMapSheetContent: View {
  @Binding var currentDetent: PresentationDetent
  let locations: [LocationShare]
  
  var body: some View {
    VStack {
      Text("Tap to move to everyone's current location")
        .font(.subheadline)
        .padding()
        .padding(.top)
      
      ScrollView([.horizontal], showsIndicators: false) {
        HStack(spacing: 20) {
          ForEach(locations, id: \.userId) { loc in
            VStack {
              KFImage(URL(string: loc.profileImageUrl ?? ""))
                .placeholder {
                  PlaceholderInitial()
                    .frame(width: 60, height: 60)
                }
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .clipped()
                .clipShape(Circle())
                .overlay(Circle().stroke(.gray, lineWidth: 1.5))
              
              Text(loc.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
            }
          }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(4)
        .padding(.horizontal)
      }
    }
    .presentationDetents([.height(0.1), .fraction(0.20)], selection: $currentDetent)
    .interactiveDismissDisabled()
    .presentationBackgroundInteraction(.enabled)
  }
}

#Preview {
  VStack {
    Color.secondary.opacity(0.3)
      .ignoresSafeArea(.all)
  }
  .sheet(isPresented: Binding.constant(true)) {
    ParticipantsMapSheetContent(
      currentDetent: Binding.constant(.fraction(0.2)),
      locations: []
      )
  }
}
