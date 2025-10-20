//
//  DateFormmatter.swift
//  puctee
//
//  Created by kj on 8/28/25.
//

import Foundation

internal func formattedDateText(from date: Date) -> String {
  let formatter = DateFormatter()
  formatter.locale = Locale(identifier: "en_US_POSIX")
  formatter.dateFormat = "yyyy/MM/dd hh:mm a"
  return formatter.string(from: date)
}
