//
//  JsonDecoder.swift
//  puctee
//
//  Created by kj on 5/12/25.
//

import Foundation

// JSON decoder that converts snake_case keys from API response JSON to camelCase
final class SnakeCaseJSONDecoder: JSONDecoder, @unchecked Sendable {
  override init() {
    super.init()
    
    // Snake → camel
    keyDecodingStrategy = .convertFromSnakeCase
    
    // ISO8601 + fractional seconds with a custom parser
    dateDecodingStrategy = .custom { decoder in
      let container = try decoder.singleValueContainer()
      let dateString = try container.decode(String.self)
      
      // Try with fractional seconds first
      let isoWithFractional = ISO8601DateFormatter()
      isoWithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
      
      if let date = isoWithFractional.date(from: dateString) {
        return date
      }
      
      // Fallback to standard format
      let iso = ISO8601DateFormatter()
      iso.formatOptions = [.withInternetDateTime]
      
      if let date = iso.date(from: dateString) {
        return date
      }
      
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Invalid ISO8601 date: \(dateString)"
      )
    }
  }
}
