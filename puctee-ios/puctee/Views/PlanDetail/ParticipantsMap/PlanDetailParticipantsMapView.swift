//
//  PlanDetailParticipantsMapView.swift
//  puctee
//
//  Created by kj on 7/2/25.
//

import SwiftUI
import MapKit
import CoreLocation

struct PlanDetailParticipantsMapView: View {
  let plan: Plan
  
  @Environment(\.planManager) private var planManager
  @Environment(\.accountManager) private var accountManager
  
  @State private var cameraPosition: MapCameraPosition
  @State private var currentDetent: PresentationDetent = .fraction(0.2)
  @State private var wsManager: LocationShareWSManager?
  @State private var locations: [Int: LocationShare] = [:]
  
  init(plan: Plan) {
    self.plan = plan
    
    // デフォルトで自分の現在地を中心に表示
    _cameraPosition = State(initialValue: .userLocation(
      followsHeading: false,
      fallback: .automatic
    ))
  }
  
  var body: some View {
    ZStack {
      Map(position: $cameraPosition) {
        
        // Destination marker
        Marker(plan.location.name, coordinate: plan.location.coordinate)
          .tint(.red)
        
        let locationArray = Array(locations.values)
        ForEach(locationArray, id: \.userId) { loc in
          let coordinate = CLLocationCoordinate2D(latitude: loc.latitude, longitude: loc.longitude)
          Annotation(String(loc.displayName), coordinate: coordinate) {
            ParticipantsMapAnnotationItem(location: loc)
              .onTapGesture {
                updateCameraPosition(to: coordinate)
              }
          }
          .annotationTitles(.hidden)
        }
        
        // Built-in annotation for user location
        UserAnnotation {
          if let currentUser = accountManager.currentUser {
            ParticipantsMapAnnotationItem(user: currentUser)
          }
        }
      }
      .mapControlVisibility(.visible)
      .mapControls {
        MapUserLocationButton()      // Current location center
        MapCompass()                 // Compass icon
        MapScaleView()               // Distance scale
      }
    }
    .navigationTitle("Everyone's Current Location")
    .navigationBarTitleDisplayMode(.inline)
    .sheet(isPresented: Binding.constant(true)) {
      ParticipantsMapSheetContent(
        currentDetent: $currentDetent,
        locations: Array(locations.values)
      )
    }
    .onAppear {
      wsManager = planManager.getWebsocket(planId: plan.id)
    }
    .onChange(of: wsManager?.locations) { oldValue, newValue in
      if let newValue = newValue {
        locations = newValue
      }
    }
  }
  
  private func updateCameraPosition(to coord: CLLocationCoordinate2D) {
    cameraPosition = .region(
      MKCoordinateRegion(
        center: coord,
        span: MKCoordinateSpan(latitudeDelta: 0.02,
                               longitudeDelta: 0.02)
      )
    )
  }
}

#Preview {
  PlanDetailParticipantsMapView(plan: SampleData.planPicnic)
}
