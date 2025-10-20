//
//  PlanEditorDateSection.swift
//  puctee
//
//  Created by kj on 5/10/25.
//

import SwiftUI

struct PlanEditorDateSection: View {
  
  @State var showDatePicker: Bool = false
  @Binding var vm: PlanEditorViewModel
  
  private var isToday: Bool {
    Calendar.current.isDateInToday(vm.startTime)
  }
  
  private var isTomorrow: Bool {
    Calendar.current.isDateInTomorrow(vm.startTime)
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Label("Date", systemImage: "calendar")
        .foregroundStyle(.gray)
      HStack(spacing: 12) {
        Button { setToday() } label: {
          Text("Today")
            .foregroundStyle(isToday ? .accent : .black)
            .padding(.vertical, 8).padding(.horizontal, 12)
            .background(isToday ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        Button { setTomorrow() } label: {
          Text("Tomorrow")
            .foregroundStyle(isTomorrow ? .blue : .black)
            .padding(.vertical, 8).padding(.horizontal, 12)
            .background(isTomorrow ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        datePickerToggle
      }
      if showDatePicker {
        DatePicker(
          "",
          selection: $vm.startTime,
          displayedComponents: .date
        )
        .datePickerStyle(.graphical)
        .labelsHidden()
      }
    }
  }
  
  // Tappable date label
  var datePickerToggle: some View {
    HStack {
      Text(DateFormatter.localizedString(from: vm.startTime, dateStyle: .medium, timeStyle: .none))
        .foregroundStyle(isToday || isTomorrow ? .black : .blue)
      Image(systemName: showDatePicker ? "chevron.up" : "chevron.down")
        .animation(.none, value: showDatePicker)
    }
    .padding(.vertical, 8).padding(.horizontal, 12)
    .background(isToday || isTomorrow ? Color.gray.opacity(0.1) : Color.blue.opacity(0.2))
    .cornerRadius(12)
    .onTapGesture {
      withAnimation(.easeInOut) {
        showDatePicker.toggle()
      }
    }
  }
  
  // MARK: Helper func
  private func setToday() {
    vm.startTime = Date()
  }
  private func setTomorrow() {
    vm.startTime = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
  }
}
