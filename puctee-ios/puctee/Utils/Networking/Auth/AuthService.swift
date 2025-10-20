//
//  AuthService.swift
//  puctee
//
//  Created by kj on 5/8/25.
//
import Foundation

enum AuthError: Error {
  case badURL, invalidResponse, serverError(Int), invalidEmailFormat
}

class AuthService {
  static let shared = AuthService()
  private init() {}
  
  private let baseUrl = Env.API.baseURL + "auth"
  
  /// Call /auth/signup to get a token
  func signup(
    email: String,
    displayName: String,
    username: String,
    password: String
  ) async throws -> AuthToken {
    // 1) Assemble the URL
    let urlString = baseUrl + "/signup"
    guard let url = URL(string: urlString) else {
      throw AuthError.badURL
    }
    
    // 2) Generate URLRequest
    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    // 3) Set the JSON body
    let body = SignupRequest(email: email, display_name: displayName, username: username, password: password)
    req.httpBody = try JSONEncoder().encode(body)
    
    // 4) Execute the request
    let (data, resp) = try await URLSession.shared.data(for: req)
    
    // 5) Check the HTTP response
    guard let http = resp as? HTTPURLResponse else {
      throw AuthError.invalidResponse
    }
    guard (200...299).contains(http.statusCode) else {
      throw AuthError.serverError(http.statusCode)
    }
    
    // 6) Decode JSON
    let token = try SnakeCaseJSONDecoder().decode(AuthToken.self, from: data)
    
    // 7) Save the token to Keychain
    saveTokens(token)
    
    return token
  }
  
  /// Call /auth/login/username to get a token
  func login(username: String, password: String) async throws -> AuthToken {
    let urlString = baseUrl + "/login/username"
    guard let url = URL(string: urlString) else {
      throw AuthError.badURL
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    
    // Percent-encode the form data and set it in the body
    var components = URLComponents()
    components.queryItems = [
      URLQueryItem(name: "username", value: username),
      URLQueryItem(name: "password", value: password)
    ]
    request.httpBody = components.percentEncodedQuery?.data(using: .utf8)
    
    // Request
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let http = response as? HTTPURLResponse, (200...300).contains(http.statusCode) else {
      throw URLError(.badServerResponse)
    }
    
    let token = try SnakeCaseJSONDecoder().decode(AuthToken.self, from: data)
    // Save the token to Keychain
    saveTokens(token)
    
    return token
  }
  
  /// Call /auth/login/email to get a token
  func login(email: String, password: String) async throws -> AuthToken {
    let urlString = baseUrl + "/login/email"
    print(urlString)
    guard let url = URL(string: urlString) else {
      throw AuthError.badURL
    }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
    
    // Percent-encode the form data and set it in the body
    var components = URLComponents()
    components.queryItems = [
      URLQueryItem(name: "email", value: email),
      URLQueryItem(name: "password", value: password)
    ]
    request.httpBody = components.percentEncodedQuery?.data(using: .utf8)
    
    // Request
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
      throw URLError(.badServerResponse)
    }
    
    let token = try SnakeCaseJSONDecoder().decode(AuthToken.self, from: data)
    // Save the token to Keychain
    saveTokens(token)
    
    return token
  }
  
  /// Call /auth/logout to log out
  func logout() async throws {
    // 1) Assemble the URL
    let urlString = baseUrl + "/logout"
    guard let url = URL(string: urlString) else {
      throw AuthError.badURL
    }
    
    // 2) Generate the request
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    // 3) Create the JSON body
    guard let refreshToken = KeychainHelper.standard.readStr(service: "refreshToken", account: "com.puctee") else {
      throw AuthError.invalidResponse
    }
    
    let body = ["refresh_token": refreshToken]
    request.httpBody = try JSONEncoder().encode(body)
    
    // 4) Execute the request
    let (_, _) = try await APIClient.shared.request(for: request)
    
    // 5) Delete the token stored in KeyChain
    KeychainHelper.standard.delete(service: "accessToken", account: "com.puctee")
    KeychainHelper.standard.delete(service: "accessExp", account: "com.puctee")
    KeychainHelper.standard.delete(service: "refreshToken", account: "com.puctee")
  }
  
  /// Send the refresh token in the JSON body to get a new token
  func refresh(refreshToken: String) async throws -> AuthToken {
    // 1) Assemble the URL
    let urlString = baseUrl + "/refresh"
    guard let url = URL(string: urlString) else {
      throw AuthError.badURL
    }
    
    // 2) Generate the request
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    // 3) Create the JSON body
    let body = ["refresh_token": refreshToken]
    request.httpBody = try JSONEncoder().encode(body)
    
    // 4) Execute the request
    let (data, response) = try await URLSession.shared.data(for: request)
    guard let http = response as? HTTPURLResponse else {
      throw AuthError.invalidResponse
    }
    guard (200...299).contains(http.statusCode) else {
      throw AuthError.serverError(http.statusCode)
    }
    
    // 5) Decode the response
    let newToken = try SnakeCaseJSONDecoder().decode(AuthToken.self, from: data)
    return newToken
  }
  
  /// Check the access token's expiration date, refresh if necessary, and add the Authorization header
  func authorizedRequest(_ req: inout URLRequest) async throws {
    let now = Date()
    // Read the access expiration from Keychain
    if let exp = KeychainHelper.standard.readDate(service: "accessExp", account: "com.puctee"),
       now >= exp {
      // Expired → Refresh
      guard let refreshToken = KeychainHelper.standard.readStr(service: "refreshToken", account: "com.puctee") else {
        throw AuthError.invalidResponse
      }
      let newToken = try await self.refresh(refreshToken: refreshToken)
      
      // Call the logic to save the new token information to Keychain here
      saveTokens(newToken)
    }
    // Set the latest access token in the header
    if let accessToken = KeychainHelper.standard.readStr(service: "accessToken", account: "com.puctee") {
      req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    }
  }
  
  /// Check if the username is available
  func validateUsername(_ username: String) async throws -> Bool {
    let urlString = baseUrl + "/validate-username/" + username
    guard let url = URL(string: urlString) else {
      throw AuthError.badURL
    }
    
    let (data, response) = try await URLSession.shared.data(from: url)
    
    // Check the HTTP response status code
    guard let httpResponse = response as? HTTPURLResponse else {
      throw AuthError.invalidResponse
    }
    
    guard httpResponse.statusCode == 200 else {
      switch httpResponse.statusCode {
        case 400:
          throw AuthError.invalidEmailFormat
        default:
          throw AuthError.serverError(httpResponse.statusCode)
      }
    }
    
    let validationResponse = try JSONDecoder().decode(UsernameValidationResponse.self, from: data)
    
    print("Successfully validated username: \(username)")
    return validationResponse.available
  }
  
  /// Check if the email has the correct format and is not already in use
  func validateEmail(_ email: String) async throws -> Bool {
    let urlString = baseUrl + "/validate-email/" + email
    guard let url = URL(string: urlString) else {
      throw AuthError.badURL
    }
    
    let (data, response) = try await URLSession.shared.data(from: url)
    
    // Check the HTTP response status code
    guard let httpResponse = response as? HTTPURLResponse else {
      throw AuthError.invalidResponse
    }
    
    switch httpResponse.statusCode {
      case 200:
        let validationResponse = try JSONDecoder().decode(EmailValidationResponse.self, from: data)
        print(validationResponse)
        return validationResponse.available
      case 400:
        throw AuthError.invalidEmailFormat
      default:
        throw AuthError.serverError(httpResponse.statusCode)
    }
  }
}

extension AuthService {
  /// Save tokens in keychain
  func saveTokens(_ token: AuthToken) {
    // save access token
    KeychainHelper.standard.saveStr(token.accessToken,
                                    service: "accessToken", account: "com.puctee")
    
    // save refresh token
    KeychainHelper.standard.saveStr(token.refreshToken,
                                    service: "refreshToken", account: "com.puctee")
    
    // save access token expiration time
    do {
      let jwt = try JWT(jwtString: token.accessToken)
      if let expDate = jwt.expiresAt {
        KeychainHelper.standard.saveDate(
          expDate,
          service: "accessExp",
          account: "com.puctee"
        )
      }
    } catch {
      print("JWT decode failed:", error)
    }
  }
}
