//
//  PlanEditorLocationPicker.swift
//  puctee
//
//  Created by kj on 5/10/25.
//

import SwiftUI
import MapKit

/// Presents a tap‑to‑select map where the caller receives a coordinate via Binding.
/// You can specify the initial camera center and zoom (span).
struct PlanEditorLocationPicker: View {
  @Environment(\.dismiss) private var dismiss
  @State private var userCenter: CLLocationCoordinate2D? = nil
  @Binding var coordinates: CLLocationCoordinate2D?
  
  /// fallback center if location permission is denied (Tokyo Station)
  private let fallbackCenter = CLLocationCoordinate2D(latitude: 35.681236, longitude: 139.767125)
  /// 緯度経度それぞれのデルタ（値を小さくすると拡大）
  var span: CLLocationDegrees = 0.01
  
  var body: some View {
    ZStack(alignment: .bottom) {
      if let center = coordinates ?? userCenter {
        CoordinatePickerMap(selected: $coordinates,
                            initialCenter: center,
                            span: span)
      } else {
        ProgressView("Getting current location...")
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .background(Color(.systemGroupedBackground))
      }
      
      Button {
        dismiss()
      } label: {
        Text("Save")
          .frame(maxWidth: .infinity)
          .bold()
          .padding(.vertical)
          .background(.accent)
          .foregroundColor(.white)
          .cornerRadius(20)
          .padding(.bottom, 44)
          .padding(.horizontal)
      }
    }
    .ignoresSafeArea()
    .navigationTitle("Select Location")
    .navigationBarTitleDisplayMode(.inline)
    .task {
      // View表示時に非同期で現在地を取得してStateに代入
      do {
        let coord = try await LocationManager.shared.getUserCoordinate()
        userCenter = coord
      } catch {
        print("Location fetch failed:", error)
      }
    }
  }
  
  private var fallbackCenterIfDenied: CLLocationCoordinate2D? {
    // If permission denied the published coordinate will stay nil; fall back.
    if CLLocationManager().authorizationStatus == .denied {
      return fallbackCenter
    }
    return nil
  }
}

// MARK: – UIKit‑backed Map
struct CoordinatePickerMap: UIViewRepresentable {
  @Binding var selected: CLLocationCoordinate2D?
  let initialCenter: CLLocationCoordinate2D
  let span: CLLocationDegrees
  
  func makeCoordinator() -> Coordinator { Coordinator(self) }
  
  func makeUIView(context: Context) -> MKMapView {
    let map = MKMapView()
    map.delegate = context.coordinator
    // Set initial region
    let region = MKCoordinateRegion(
      center: initialCenter,
      span: MKCoordinateSpan(latitudeDelta: span, longitudeDelta: span)
    )
    map.setRegion(region, animated: false)
    map.isRotateEnabled = false
    map.showsUserLocation = true
    
    // tap recogniser
    let tap = UITapGestureRecognizer(
      target: context.coordinator,
      action: #selector(Coordinator.handleTap(_:))
    )
    map.addGestureRecognizer(tap)
    return map
  }
  
  func updateUIView(_ map: MKMapView, context: Context) {
    map.removeAnnotations(map.annotations)
    if let c = selected {
      let pin = MKPointAnnotation()
      pin.coordinate = c
      map.addAnnotation(pin)
      // Option: Recenter region when pin is selected
      if !map.region.contains(c) {
        let region = MKCoordinateRegion(center: c,
                                        span: MKCoordinateSpan(latitudeDelta: span,
                                                               longitudeDelta: span))
        map.setRegion(region, animated: true)
      }
    }
  }
  
  // MARK: – Coordinator
  class Coordinator: NSObject, MKMapViewDelegate {
    var parent: CoordinatePickerMap
    init(_ parent: CoordinatePickerMap) { self.parent = parent }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
      guard let map = gesture.view as? MKMapView else { return }
      let point = gesture.location(in: map)
      let coord = map.convert(point, toCoordinateFrom: map)
      parent.selected = coord
    }
  }
  }


private extension MKCoordinateRegion {
  /// Returns true if the coordinate is within the current visible region.
  func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
    let north = center.latitude + span.latitudeDelta / 2
    let south = center.latitude - span.latitudeDelta / 2
    let east = center.longitude + span.longitudeDelta / 2
    let west = center.longitude - span.longitudeDelta / 2
    return (south...north).contains(coordinate.latitude) &&
    (west...east).contains(coordinate.longitude)
  }
}

#Preview {
  @Previewable @State var selected: CLLocationCoordinate2D? = nil
  PlanEditorLocationPicker(coordinates: $selected)
}
