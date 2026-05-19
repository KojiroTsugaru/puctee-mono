//
//  ReportContentSheet.swift
//  puctee
//
//  Created by kj on 11/4/25.
//

import SwiftUI

struct ReportContentSheet: View {
  @Environment(\.dismiss) private var dismiss
  
  let contentType: ContentReportType
  let contentId: Int?
  let reportedUserId: Int?
  
  @State private var selectedReason: ContentReportReason = .inappropriate
  @State private var additionalDetails = ""
  @State private var isSubmitting = false
  @State private var showSuccessAlert = false
  @State private var showErrorAlert = false
  @State private var errorMessage = ""
  
  var body: some View {
    NavigationView {
      Form {
        Section {
          Text("Help us understand what's wrong with this content")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        
        Section(header: Text("Reason")) {
          Picker("Select a reason", selection: $selectedReason) {
            ForEach(ContentReportReason.allCases, id: \.self) { reason in
              VStack(alignment: .leading, spacing: 4) {
                Text(reason.displayName)
                  .font(.body)
                Text(reason.description)
                  .font(.caption)
                  .foregroundColor(.secondary)
              }
              .tag(reason)
            }
          }
          .pickerStyle(.inline)
        }
        
        Section(header: Text("Additional Details (Optional)")) {
          TextEditor(text: $additionalDetails)
            .frame(minHeight: 100)
            .overlay(
              Group {
                if additionalDetails.isEmpty {
                  Text("Provide more context about this report...")
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
                    .padding(.leading, 4)
                    .allowsHitTesting(false)
                }
              },
              alignment: .topLeading
            )
        }
        
        Section {
          Text("Reports are reviewed within 24 hours. False reports may result in account restrictions.")
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }
      .navigationTitle("Report Content")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
        
        ToolbarItem(placement: .confirmationAction) {
          Button("Submit") {
            submitReport()
          }
          .disabled(isSubmitting)
        }
      }
      .alert("Report Submitted", isPresented: $showSuccessAlert) {
        Button("OK") {
          dismiss()
        }
      } message: {
        Text("Thank you for helping keep our community safe. We'll review this report within 24 hours.")
      }
      .alert("Error", isPresented: $showErrorAlert) {
        Button("OK") {}
      } message: {
        Text(errorMessage)
      }
    }
  }
  
  private func submitReport() {
    isSubmitting = true
    
    Task {
      do {
        let report = ContentReportCreate(
          reportedUserId: reportedUserId,
          contentType: contentType,
          contentId: contentId,
          reason: selectedReason,
          description: additionalDetails.isEmpty ? nil : additionalDetails
        )
        
        try await ModerationService.shared.reportContent(report)
        
        await MainActor.run {
          isSubmitting = false
          showSuccessAlert = true
        }
      } catch {
        await MainActor.run {
          isSubmitting = false
          errorMessage = "Failed to submit report. Please try again."
          showErrorAlert = true
        }
      }
    }
  }
}

#Preview {
  ReportContentSheet(
    contentType: .penaltyRequest,
    contentId: 1,
    reportedUserId: 2
  )
}
