//
//  AuthDTO.swift
//  puctee
//
//  Created by kj on 5/12/25.
//

import Foundation

// ───────────────────────────────
// Request body for Signup
// ───────────────────────────────
struct SignupRequest: Codable {
  let email: String
  let display_name: String
  let username: String
  let password: String
}

// ───────────────────────────────
// Common token response for signup/login
// ───────────────────────────────
struct AuthToken: Codable {
  let accessToken: String
  let tokenType: String
  let refreshToken: String
}

struct UsernameValidationResponse: Codable {
  let available: Bool
  let message: String
}

struct EmailValidationResponse: Codable {
  let available: Bool
  let message: String
}
