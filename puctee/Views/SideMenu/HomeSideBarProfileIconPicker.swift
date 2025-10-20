//
//  SideBarProfileIcon.swift
//  puctee
//
//  Created by kj on 7/29/25.
//

import SwiftUI
import PhotosUI
import Kingfisher

struct HomeSideBarProfileIconPicker: View {
  @Environment(\.accountManager) private var accountManager
  @Binding var isShowingPhotoPicker: Bool
  
  @State private var profileImageData: Data?
  @State private var profileImage: UIImage?
  @State private var selectedPhotoItem: PhotosPickerItem?
  
  var body: some View {
    NavigationStack {
      VStack(spacing: 40) {
        Spacer()
        Text("Change profile picture")
          .multilineTextAlignment(.center)
          .font(.title3).fontWeight(.bold)
        
        ZStack {
          if let uiImage = profileImage {
            Image(uiImage: uiImage)
              .resizable()
          } else {
            KFImage(accountManager.currentUser?.profileImageUrl)
              .placeholder {
                PlaceholderInitial()
                  .frame(width: 120, height: 120)
              }
              .resizable()
          }
        }
        .scaledToFill()
        .frame(width: 120, height: 120)
        .clipShape(Circle())
        .overlay(Circle().stroke(.gray, lineWidth: 1))
        .padding()
        
        PhotosPicker(
          selection: $selectedPhotoItem,
          matching: .images,
          photoLibrary: .shared()
        ) {
          Text(profileImageData == nil ? "Select photo" : "Change photo")
            .font(.headline).fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(width: 200)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 12)
              .fill(Color.accentColor))
        }
        // Handle selection and update preview
        .onChange(of: selectedPhotoItem) { _, newItem in
          Task {
            if let item = newItem,
               let data = try? await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
              // Update state on main actor
              profileImageData = data
              profileImage = uiImage
            }
          }
        }
        
        Spacer()
      }
      .padding()
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel") {
            isShowingPhotoPicker = false
            profileImageData = nil
            profileImage = nil
          }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Save") {
            if let data = profileImageData {
              Task {
                do {
                  try await accountManager.uploadProfileImage(imageData: data)
                } catch {
                  print("⚠️ failed to upload icon:", error)
                }
              }
            }
            isShowingPhotoPicker = false
            profileImageData = nil
            profileImage = nil
          }
          .disabled(profileImageData == nil)
        }
      }
    }
  }
}
