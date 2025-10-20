//
//  ApprovalRequestRow.swift
//  puctee
//
//  Created by kj on 9/1/25.
//

import SwiftUI

struct ApprovalRequestRow: View {
  let request: PenaltyApprovalRequestResponse
  var onViewMore: () -> Void
  
  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      // 送信者アイコン（イニシャル）
      InitialsAvatar(name: request.penaltyName)
        .frame(width: 44, height: 44)
      
      // 吹き出し
      VStack(alignment: .leading, spacing: 6) {
        HStack(spacing: 8) {
          Text(request.penaltyName)
            .font(.subheadline).fontWeight(.semibold)
          statusBadge
          Spacer()
          Text(request.createdAt, style: .time)
            .font(.caption).foregroundStyle(.secondary)
        }
        
        SpeechBubble(
          cornerRadius: 12,
          // 左にしっぽ
          tail: .left
        ) {
          VStack(alignment: .leading, spacing: 8) {
            if let c = request.comment, !c.isEmpty {
              Text(c)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineLimit(3)
            } else {
              Text("No comment")
                .foregroundStyle(.secondary)
                .font(.subheadline)
            }
            
            if let url = request.proofImageUrl {
              AsyncImage(url: url) { phase in
                switch phase {
                  case .empty: ProgressView()
                  case .success(let img):
                    img.resizable()
                      .scaledToFill()
                      .frame(height: 120)
                      .clipShape(RoundedRectangle(cornerRadius: 10))
                  case .failure: EmptyView()
                  @unknown default: EmptyView()
                }
              }
            }
            
            HStack {
              Spacer()
              Button("View more") { onViewMore() }
                .font(.subheadline.weight(.semibold))
                .buttonStyle(.bordered)
            }
          }
          .padding(12)
        }
      }
    }
    .padding(.vertical, 8)
  }
  
  // ステータスの小バッジ
  private var statusBadge: some View {
    let (label, color): (String, Color) = {
      switch request.status {
        case .pending:  return ("Pending",  .yellow)
        case .approved: return ("Approved", .green)
        case .declined: return ("Declined", .red)
      }
    }()
    return Text(label)
      .font(.caption2.bold())
      .padding(.horizontal, 8).padding(.vertical, 3)
      .background(color.opacity(0.18))
      .foregroundStyle(color)
      .clipShape(Capsule())
  }
}

// イニシャル丸アイコン
private struct InitialsAvatar: View {
  let name: String
  var body: some View {
    let initials = name.split(separator: " ")
      .prefix(2)
      .compactMap { $0.first }
      .map(String.init)
      .joined()
      .uppercased()
    return Text(initials.isEmpty ? "U" : initials)
      .font(.headline)
      .foregroundStyle(.white)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(
        LinearGradient(colors: [.mint, .teal], startPoint: .top, endPoint: .bottom)
      )
      .clipShape(Circle())
      .overlay(Circle().strokeBorder(.white, lineWidth: 2))
      .shadow(radius: 1, y: 1)
  }
}

// 汎用 吹き出しビュー
private struct SpeechBubble<Content: View>: View {
  enum Tail { case left, right, none }
  var cornerRadius: CGFloat = 12
  var tail: Tail = .left
  @ViewBuilder var content: Content
  
  var body: some View {
    ZStack(alignment: tail == .left ? .bottomLeading : .bottomTrailing) {
      RoundedRectangle(cornerRadius: cornerRadius)
        .fill(.ultraThinMaterial)
      
      content
      
      if tail != .none {
        Triangle()
          .fill(.ultraThinMaterial)
          .frame(width: 12, height: 10)
          .rotationEffect(.degrees(tail == .left ? 0 : 180))
          .offset(x: tail == .left ? 16 : -16, y: 5)
      }
    }
  }
  
  private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
      var p = Path()
      p.move(to: CGPoint(x: rect.midX, y: rect.minY))
      p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
      p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
      p.closeSubpath()
      return p
    }
  }
}
