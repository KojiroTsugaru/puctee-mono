//
//  APIResponseError.swift
//  puctee
//
//  Created by kj on 7/30/25.
//

import Foundation

enum APIResponseError : Error {
  case invalidResponse(status: Int, data: Data)
  case invalidData
  case invalidDecoding
}
