//
//  PlanEditorLocationSection.swift
//  puctee
//
//  Created by kj on 5/10/25.
//

import SwiftUI
import MapKit

struct PlanEditorLocationSection: View {
  @Binding var vm: PlanEditorViewModel
  @Binding var showCoordinatePicker: Bool
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Image(systemName: "mappin").foregroundStyle(.gray)
        UnderlinedTextField("Enter location name",
                            text: $vm.locationNameText,
                            font: .preferredFont(forTextStyle: .body))
      }
      
      // MapKit to pick location on map
      ZStack {
        if vm.selectedCoordinates != nil {
          StaticMapView(coordinate: vm.selectedCoordinates!)
        } else {
          Color.gray.opacity(0.1)
          VStack(spacing: 8) {
            Image(systemName: "plus.circle")
            Text("Tap to specify location from map")
              .font(.caption)
          }.foregroundStyle(.primary.opacity(0.8))
        }
      }.clipShape(RoundedRectangle(cornerRadius: 12))
        .frame(height: 80)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .onTapGesture {
          showCoordinatePicker.toggle()
        }
      if let err = vm.locationError {
        Text(err)
          .font(.caption)
          .foregroundColor(.red)
      }
    }
  }
  
  /// A static map that centers on the given coordinates and does not accept any user interaction.
  struct StaticMapView: View {
    let coordinate: CLLocationCoordinate2D
    var span: CLLocationDegrees = 0.005   // Zoom level
    
    private var region: MKCoordinateRegion {
      .init(center: coordinate,
            span: .init(latitudeDelta: span, longitudeDelta: span))
    }
    
    var body: some View {
      Map(                                      // ← New API
        position: .constant(.region(region)), // MapCameraPosition
        interactionModes: []                  // All operations off
      ) {
        Marker("", coordinate: coordinate)    // iOS 17 Marker
          .tint(.red)
      }
    }
  }
}
