//
//  WebsocketClient.swift
//  puctee
//
//  Created by kj on 9/7/25.
//

import Supabase
import Realtime

class WebsocketClient {
  static let shared = WebsocketClient()
  
  private init() { }
  
  private let supabase = SupabaseClient(
    supabaseURL: Env.Supabase.supabaseUrl,
    supabaseKey: Env.Supabase.supabaseKey
  )
  
  // Supabaseクライアントへのアクセス
  var client: SupabaseClient {
    return supabase
  }
  
  // チャンネルを取得
  func getChannel(channelId: String) async -> RealtimeChannelV2 {
    return await supabase.realtimeV2.channel(channelId)
  }
  
  // データベースアクセス
  var database: PostgrestClient {
    return supabase.database
  }
}
