//
//  LocationAlwaysPermissionModal.swift
//  puctee
//
//  Created by kj on 10/20/25.
//

import SwiftUI

struct LocationAlwaysPermissionModal: View {
  @Binding var isPresented: Bool
  @Environment(\.colorScheme) private var colorScheme
  
  var body: some View {
    ZStack {
      Color.black.opacity(0.5)
        .ignoresSafeArea()
        .onTapGesture {
          withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isPresented = false
          }
        }
      
      VStack(spacing: 0) {
        // Header with gradient background
        VStack(spacing: 16) {
          ZStack {
            Circle()
              .fill(
                LinearGradient(
                  colors: [Color.accentColor.opacity(0.2), Color.accentColor.opacity(0.1)],
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                )
              )
              .frame(width: 80, height: 80)
            
            Image(systemName: "location.circle.fill")
              .font(.system(size: 40))
              .foregroundStyle(
                LinearGradient(
                  colors: [Color.accentColor, Color.accentColor.opacity(0.7)],
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                )
              )
          }
          .padding(.top, 8)
          
          VStack(spacing: 8) {
            Text("Enable Always Location")
              .font(.title2)
              .fontWeight(.bold)
              .multilineTextAlignment(.center)
            
            Text("For reliable arrival tracking")
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
        }
        .padding(.top, 32)
        .padding(.bottom, 24)
        
        // Benefits section
        VStack(spacing: 16) {
          ForEach(benefits, id: \.title) { benefit in
            ModernBenefitRow(
              icon: benefit.icon,
              title: benefit.title,
              description: benefit.description
            )
          }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 28)
        
        // Buttons
        VStack(spacing: 12) {
          Button {
            openSettings()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
              isPresented = false
            }
          } label: {
            HStack(spacing: 8) {
              Text("Open Settings")
                .fontWeight(.semibold)
              Image(systemName: "arrow.right")
                .font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
              LinearGradient(
                colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                startPoint: .leading,
                endPoint: .trailing
              )
            )
            .cornerRadius(14)
            .shadow(color: Color.accentColor.opacity(0.3), radius: 8, y: 4)
          }
          
          Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
              isPresented = false
            }
          } label: {
            Text("Maybe Later")
              .font(.subheadline)
              .fontWeight(.medium)
              .foregroundColor(.secondary)
              .frame(maxWidth: .infinity)
              .padding(.vertical, 12)
          }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
      }
      .background(
        RoundedRectangle(cornerRadius: 28)
          .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemBackground))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 28)
          .strokeBorder(
            colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.05),
            lineWidth: 1
          )
      )
      .padding(.horizontal, 28)
      .shadow(color: Color.black.opacity(0.2), radius: 30, y: 10)
    }
  }
  
  private var benefits: [(icon: String, title: String, description: String)] {
    [
      (
        icon: "checkmark.circle.fill",
        title: "Auto Arrival Check",
        description: "Verify your arrival automatically"
      ),
      (
        icon: "chart.line.uptrend.xyaxis.circle.fill",
        title: "Trust Score Tracking",
        description: "Accurate trust level updates"
      ),
      (
        icon: "bell.badge.circle.fill",
        title: "Background Updates",
        description: "Reliable notifications anytime"
      )
    ]
  }
  
  private func openSettings() {
    if let url = URL(string: UIApplication.openSettingsURLString) {
      UIApplication.shared.open(url)
    }
  }
}

struct ModernBenefitRow: View {
  let icon: String
  let title: String
  let description: String
  
  var body: some View {
    HStack(spacing: 14) {
      ZStack {
        Circle()
          .fill(Color.accentColor.opacity(0.12))
          .frame(width: 44, height: 44)
        
        Image(systemName: icon)
          .font(.system(size: 18, weight: .semibold))
          .foregroundColor(.accentColor)
      }
      
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.subheadline)
          .fontWeight(.semibold)
          .foregroundColor(.primary)
        
        Text(description)
          .font(.caption)
          .foregroundColor(.secondary)
      }
      
      Spacer()
    }
    .padding(.vertical, 4)
  }
}

#Preview {
  LocationAlwaysPermissionModal(isPresented: .constant(true))
}
