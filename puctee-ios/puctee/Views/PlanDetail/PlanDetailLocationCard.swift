//
//  PlanDetailLocationCard.swift
//  puctee
//
//  Created by kj on 5/18/25.
//

import SwiftUI
import MapKit

/// A static map that centers on the given coordinates and does not accept any user interaction.
struct PlanDetailLocationCard: View {
  let plan: Plan
  
  @Environment(\.planManager) private var planManager
  
  var span: CLLocationDegrees = 0.005   // Zoom level
  private var coordinate: CLLocationCoordinate2D {
    CLLocationCoordinate2D(latitude: plan.location.latitude, longitude: plan.location.longitude)
  }
  
  private var region: MKCoordinateRegion {
    .init(center: coordinate,
          span: .init(latitudeDelta: span, longitudeDelta: span))
  }
  
  @State private var showParticipantsMap: Bool = false
  
  private var isLocationShareDisabled: Bool {
    planManager.getWebsocket(planId: plan.id) == nil
  }
  
  var body: some View {
    VStack(spacing: 16) {
      HStack {
        Label(plan.location.name, systemImage: "mappin.and.ellipse")
          .font(.subheadline)
          .foregroundColor(.secondary)
        Spacer()
      }
      
      Map(
        position: .constant(.region(region)),
        interactionModes: []
      ) {
        Marker("", coordinate: coordinate)
          .tint(.red)
      }
      .frame(height: 140)
      .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
      .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
      
      actionButtons
      
      if isLocationShareDisabled {
        Text("Location check is available 15 min before the plan starts")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
    }
    .padding()
    .background(.regularMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    .shadow(color: .black.opacity(0.1), radius: 6, x: 0, y: 3)
  }
  
  private var actionButtons: some View {
    HStack(spacing: 12) {
      // Button to check everyone's location
      NavigationLink {
        PlanDetailParticipantsMapView(plan: plan)
      } label: {
        Label("Their Location", systemImage: "antenna.radiowaves.left.and.right")
          .font(.subheadline.bold())
          .frame(maxWidth: .infinity)
          .padding(.vertical, 12)
          .background(Color(.green).gradient)
          .foregroundColor(.white)
          .clipShape(Capsule())
      }
      .buttonStyle(PlainButtonStyle())
      .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
      .disabled(isLocationShareDisabled)
      
      // Button to open Map
      Button {
        openMapsApp(to: coordinate)
      } label: {
        Label("Check Route", systemImage: "arrow.trianglehead.turn.up.right.diamond.fill")
          .font(.subheadline.bold())
          .frame(maxWidth: .infinity)
          .padding(.vertical, 12)
          .background(Color.accentColor.gradient)
          .foregroundColor(.white)
          .clipShape(Capsule())
      }
      .buttonStyle(PlainButtonStyle())
      .shadow(color: Color.accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
    }
    .padding(.top, 12)
  }
  
  private func openMapsApp(to coordinate: CLLocationCoordinate2D) {
    let lat = coordinate.latitude
    let lon = coordinate.longitude
    
    // 1) Assemble Google Maps scheme URL
    if let googleURL = URL(string: "comgooglemaps://?daddr=\(lat),\(lon)&directionsmode=driving"),
       UIApplication.shared.canOpenURL(googleURL) {
      UIApplication.shared.open(googleURL, options: [:])
    }
    else {
      // 2) If Google Maps is not installed, open with Apple Maps
      let appleURL = URL(string: "http://maps.apple.com/?daddr=\(lat),\(lon)&dirflg=d")!
      UIApplication.shared.open(appleURL, options: [:])
    }
  }
}

#Preview {
  PlanDetailLocationCard(plan: SampleData.planPicnic)
}
