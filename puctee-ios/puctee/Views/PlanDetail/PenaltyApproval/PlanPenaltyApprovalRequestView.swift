//
//  PlanPenaltyApprovalRequestView.swift
//  puctee
//
//  Created by kj on 8/20/25.
//

import SwiftUI
import PhotosUI

struct PlanPenaltyApprovalRequestView: View {
  let plan: Plan?
  
  @Binding var isPresented: Bool
  @State private var pickerItem: PhotosPickerItem?
  @State private var photoData: Data?
  @State private var isLoadingPhoto = false
  @State private var comment = ""
  @State private var showSentAlert = false
  @State private var showErrorAlert = false
  @State private var isSending = false
  @FocusState private var isCommentFocused: Bool
  
  private var isSolo: Bool {
    plan?.participants.count == 1
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      // close button
      HStack {
        Button {
          isPresented.toggle()
        } label: {
          Image(systemName: "xmark")
            .font(.system(size: 28))
            .foregroundStyle(.gray)
        }
        Spacer()
      }
      
      // Title
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Image(systemName: "tag.fill")
          Text("Penalty:")
        }
        .font(.system(size: 16, weight: .semibold))
        
        Text(plan?.penalties?.first?.content ?? "")
          .font(.system(size: 24, weight: .bold))
      }
      .padding(.top, 8)
      
      // Photo card (uploaded or placeholder)
      PhotoCard(
        imageData: photoData,
        isLoading: isLoadingPhoto
      )
      .overlay(
        PhotosPicker(selection: $pickerItem, matching: .images) {
          Color.clear.contentShape(Rectangle()) // full-card tappable
        }
      )
      
      // Rounded comment field like screenshot
      CommentField(text: $comment, isFocused: $isCommentFocused)
      
      // Action buttons
      VStack(spacing: 20) {
        if isSending {
          HStack {
            ProgressView()
            Text(isSolo ? "Approving penalty for myself..." : "Sending an approval request...")
          }
          .font(.caption)
        }
        
        Button(action: {
          handleSendApproval()
        }) {
          Label(isSolo ? "Approve Myself" : "Send for Approval", systemImage: "paperplane")
            .font(.system(size: 16, weight: .bold))
        }
        .buttonStyle(CapsuleFillButtonStyle(.red))
        
        Button("Cancel") { isPresented.toggle() }
          .font(.system(size: 16))
          .foregroundColor(.primary)
          .padding(.bottom, 8)
      }
    }
    .padding(20)
    .simultaneousGesture(
      TapGesture().onEnded { _ in
        isCommentFocused = false
      }
    )
    .alert(isSolo ? "Approved Penalty!" : "Sent approval request!", isPresented: $showSentAlert) {
      Button("OK", role: .cancel) { isPresented = false }
    }
    .alert("NetWork Error. Try again later", isPresented: $showErrorAlert) {
      Button("OK", role: .cancel) { }
    }
    .onChange(of: pickerItem) { _, newValue in
      guard let item = newValue else { return }
      isLoadingPhoto = true
      Task {
        defer { isLoadingPhoto = false }
        if let data = try? await item.loadTransferable(type: Data.self) {
          photoData = data
        }
      }
    }
  }
  
  private func handleSendApproval() {
    Task {
      isSending = true
      if let planId = plan?.id {
        do {
          let request = PenaltyApprovalRequest(comment: comment, proof_image_data: photoData?.base64EncodedString())
          try await PlanService.shared.requestPenaltyApproval(planId: planId, request: request, isSolo: isSolo)
          showSentAlert.toggle()
          isSending = false
        } catch {
          showErrorAlert.toggle()
          isSending = false
        }
      }
    }
  }
}

// MARK: - Subviews

private struct PhotoCard: View {
  let imageData: Data?
  let isLoading: Bool
  
  private let corner: CGFloat = 16
  
  var body: some View {
    ZStack {
      Color(.secondarySystemBackground)
      
      if isLoading {
        ProgressView()
      } else if let data = imageData, let uiImg = UIImage(data: data) {
        Image(uiImage: uiImg)
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .accessibilityLabel("Uploaded proof image")
      } else {
        VStack(spacing: 8) {
          Image(systemName: "photo.badge.plus")
            .font(.system(size: 32))
            .foregroundColor(.secondary)
          Text("Upload Proof")
            .font(.headline)
            .foregroundColor(.secondary)
          Text("(optional)")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }
    }
    .frame(height: 360)
    .frame(width: 360)
    .mask(
      RoundedRectangle(cornerRadius: corner, style: .continuous)
    )
    .compositingGroup()
    .overlay(
      RoundedRectangle(cornerRadius: corner, style: .continuous)
        .stroke(Color(.quaternaryLabel), lineWidth: 0.5)
    )
    .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
    .contentShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
  }
}

private struct CommentField: View {
  @Binding var text: String
  @FocusState.Binding var isFocused: Bool
  
  var body: some View {
    ZStack(alignment: .leading) {
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .fill(Color(.systemBackground))
        .overlay(
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(Color(.quaternaryLabel), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 2, x: 0, y: 1)
      
      TextField("Add a comment (optional)", text: $text, axis: .vertical)
        .focused($isFocused)
        .submitLabel(.done)
        .onSubmit { isFocused = false }
        .onChange(of: text) { _, newValue in
          if newValue.last == "\n" {
            text.removeLast()
            isFocused = false
          }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .font(.body)
    }
    .frame(height: 56)
  }
}

#Preview {
  NavigationStack {
    PlanPenaltyApprovalRequestView(plan: SampleData.planPicnic, isPresented: Binding.constant(true))
  }
  .preferredColorScheme(.light)
}
