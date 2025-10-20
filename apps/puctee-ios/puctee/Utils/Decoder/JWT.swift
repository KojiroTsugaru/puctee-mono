//
//  JWT.swift
//  puctee
//
//  Created by kj on 5/13/25.
//

import Foundation

struct JWT {
  let header: [String:Any]
  let payload: [String:Any]
  
  init(jwtString: String) throws {
    let parts = jwtString.split(separator: ".")
    guard parts.count == 3 else { throw JWTError.invalidFormat }
    
    func decodeBase64URL(_ str: String) throws -> Data {
      var s = str
        .replacingOccurrences(of: "-", with: "+")
        .replacingOccurrences(of: "_", with: "/")
      let padLen = 4 - s.count % 4
      if padLen < 4 { s += String(repeating: "=", count: padLen) }
      guard let d = Data(base64Encoded: s) else {
        throw JWTError.base64DecodeFailed
      }
      return d
    }
    
    let headerData = try decodeBase64URL(String(parts[0]))
    let payloadData = try decodeBase64URL(String(parts[1]))
    guard
      let headerObj = try JSONSerialization.jsonObject(with: headerData) as? [String:Any],
      let payloadObj = try JSONSerialization.jsonObject(with: payloadData) as? [String:Any]
    else {
      throw JWTError.jsonDecodeFailed
    }
    
    self.header = headerObj
    self.payload = payloadObj
  }
  
  var expiresAt: Date? {
    if let exp = payload["exp"] as? TimeInterval {
      return Date(timeIntervalSince1970: exp)
    }
    return nil
  }
}

enum JWTError: Error {
  case invalidFormat, base64DecodeFailed, jsonDecodeFailed
}
