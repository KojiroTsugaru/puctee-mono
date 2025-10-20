//
//  Environment.swift
//  puctee
//
//  Created by kj on 5/12/25.
//

import Foundation

enum Env {
  public struct API {
    // lambda function url
    // private static let remoteBaseURL = "https://cpl2pbkrsgdc3uniccl6kmdqg40mntzp.lambda-url.ap-northeast-1.on.aws/api/"
    
    // APIGateway invoke url for dev-1
    private static let remoteBaseURL = "https://qiyzekbq43.execute-api.ap-northeast-1.amazonaws.com/dev-1/api/"
    
    /// test on physical device
    private static let localBaseURL = "https://082de17d2c87.ngrok-free.app/api/"
    
    /// localhost
    // private static let localBaseURL = "http://127.0.0.1:8000/api/"
    
    /// 本番／開発で切り替えてくれる“現在の”APIベースURL
    static var baseURL: String {
        #if DEBUG
          return Self.localBaseURL
        #else
          return Self.remoteBaseURL
        #endif
      }
  }
  
  public struct Supabase {
    static let supabaseUrl = URL(string: "https://qxgzeceqwpffzzpuygtm.supabase.co")!
    
    static let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF4Z3plY2Vxd3BmZnp6cHV5Z3RtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTcyODQ0OTIsImV4cCI6MjA3Mjg2MDQ5Mn0.de9XC0_lLq9_2RGLbA2NmcdcEBZyVSDzBE7VIaVcAM8"
  }
}
  
