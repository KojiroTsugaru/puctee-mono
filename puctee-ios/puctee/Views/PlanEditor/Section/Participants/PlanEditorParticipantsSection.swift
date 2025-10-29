//
//  PlanEditorParticipantsSection.swift
//  puctee
//
//  Created by kj on 5/10/25.
//

import SwiftUI
import Kingfisher

struct PlanEditorParticipantsSection: View {
  @Bindable var vm: PlanEditorViewModel
  @State private var showParticipantSearch: Bool = false
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 12) {
        Label("参加者:", systemImage: "person.2.fill")
          .foregroundStyle(.gray)
        
        HStack(spacing: -8) {
          ForEach(vm.participants) { participant in
            KFImage(participant.profileImageUrl)
              .placeholder {                   
                PlaceholderInitial()
                  .frame(width: 32, height: 32)
              }
              .resizable()
              .scaledToFill()
              .frame(width: 32, height: 32)
              .clipped()
              .clipShape(Circle())
              .overlay(Circle().stroke(Color(.systemGray4), lineWidth: 1))
          }
          // Show extra count
          .navigationDestination(isPresented: $showParticipantSearch) {
            PlanEditorParticipantSearchView(vm: vm)
          }
          Image(systemName: "plus")
            .font(.caption2)
            .foregroundColor(.accentColor)
            .frame(width: 32, height: 32)
            .background(Circle().fill(Color.secondary.opacity(0.1)))
            .overlay(Circle().stroke(Color(.systemGray4), lineWidth: 1))
            .onTapGesture {
              showParticipantSearch.toggle()
            }
        }
        Spacer()
        ForEach(vm.participants) { participant in
          Text(participant.username)
            .font(.caption2)
            .fontWeight(.light)
            .lineLimit(0)
        }
      }
    }
  }
}
