//
//  Location.swift
//  puctee
//
//  Created by kj on 5/9/25.
//

import Foundation
import CoreLocation

struct Location: Codable {
  let name: String
  let latitude: Double
  let longitude: Double
  
  var coordinate: CLLocationCoordinate2D {
    return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
  }
}

extension Location {
  init(from response: LocationResponse) {
    self.name = response.name
    self.latitude = response.latitude
    self.longitude = response.longitude
  }
}
