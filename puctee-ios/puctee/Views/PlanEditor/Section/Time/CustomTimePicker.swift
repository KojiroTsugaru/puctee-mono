//
//  CustomTimePicker.swift
//  puctee
//
//  Created by kj on 5/21/25.
//
import SwiftUI

/// 整数＋サフィックス版ホイール
struct SuffixWheelStack: View {
  let values: [Int]
  let suffix: String
  @Binding var selection: Int
  
  private let itemHeight: CGFloat = 50
  
  var body: some View {
    GeometryReader { geo in
      ScrollViewReader { reader in
        ScrollView(.vertical, showsIndicators: false) {
          VStack(spacing: 0) {
            ForEach(values, id: \.self) { v in
              Text(String(format: "%02d", v) + " \(suffix)")
                .frame(height: itemHeight)
                .font(v == selection ? .title2.weight(.bold) : .body)
                .scaleEffect(v == selection ? 1.1 : 1)
                .opacity(v == selection ? 1 : 0.5)
                .id(v)
                .onTapGesture {
                  withAnimation { selection = v }
                }
            }
          }
          .onChange(of: selection) { _, new in
            withAnimation { reader.scrollTo(new, anchor: .center) }
          }
        }
        .onAppear {
          reader.scrollTo(selection, anchor: .center)
        }
        // 上下矢印
        .overlay(
          VStack {
            Image(systemName: "chevron.up")
            Spacer()
            Image(systemName: "chevron.down")
          }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(.vertical, 8)
            .allowsHitTesting(false)
        )
      }
    }
    .frame(width: 100)
  }
}

/// 文字列版ホイール（AM/PM 用）
struct StringWheelStack: View {
  let values: [String]
  @Binding var selection: String
  
  private let itemHeight: CGFloat = 50
  
  var body: some View {
    GeometryReader { geo in
      let totalH = geo.size.height
      ScrollViewReader { reader in
        ScrollView(.vertical, showsIndicators: false) {
          VStack(spacing: 0) {
            Color.clear.frame(height: (totalH - itemHeight)/2)
            ForEach(values, id: \.self) { v in
              Text(v)
                .frame(height: itemHeight)
                .font(v == selection ? .title2.weight(.bold) : .body)
                .scaleEffect(v == selection ? 1.1 : 1)
                .opacity(v == selection ? 1 : 0.5)
                .id(v)
                .onTapGesture {
                  withAnimation { selection = v }
                }
            }
            Color.clear.frame(height: (totalH - itemHeight)/2)
          }
          .onChange(of: selection) { _, new in
            withAnimation { reader.scrollTo(new, anchor: .center) }
          }
        }
        .onAppear {
          reader.scrollTo(selection, anchor: .center)
        }
        .overlay(
          Rectangle()
            .stroke(Color.primary.opacity(0.2), lineWidth: 1)
            .frame(height: itemHeight)
        )
      }
    }
    .frame(width: 60)
  }
}

/// 12h＋AM/PM＋分 のホイールデザイン
struct CustomTimePicker: View {
  @Binding var date: Date
  
  @State private var hour12: Int = 12
  @State private var minute: Int = 0
  @State private var period: String = "AM"
  
  private let hours = Array(1...12)
  private let minutes = Array(0...59)
  private let periods = ["AM", "PM"]
  private let pickerH: CGFloat = 200
  
  var body: some View {
    HStack(alignment: .center, spacing: 4) {
      // Hour
      SuffixWheelStack(values: hours, suffix: "h", selection: $hour12)
      // Colon
      Text(":")
        .font(.title2.weight(.semibold))
        .padding(.bottom, 8)
      // Minute
      SuffixWheelStack(values: minutes, suffix: "m", selection: $minute)
      // AM/PM
      StringWheelStack(values: periods, selection: $period)
    }
    .frame(height: pickerH)
    .onAppear(perform: syncFromDate)
    .onChange(of: hour12) { _, _ in updateDate() }
    .onChange(of: minute)   { _, _ in updateDate() }
    .onChange(of: period)   { _, _ in updateDate() }
  }
  
  private func syncFromDate() {
    let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
    let h24 = comps.hour ?? 0
    minute = comps.minute ?? 0
    if h24 >= 12 {
      period = "PM"
      hour12 = h24 == 12 ? 12 : h24 - 12
    } else {
      period = "AM"
      hour12 = h24 == 0 ? 12 : h24
    }
  }
  
  private func updateDate() {
    var h = (period == "PM" ? (hour12 % 12) + 12 : hour12 % 12)
    if period == "AM" && hour12 == 12 { h = 0 }
    var comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
    comps.hour = h
    comps.minute = minute
    if let newD = Calendar.current.date(from: comps) {
      date = newD
    }
  }
}
