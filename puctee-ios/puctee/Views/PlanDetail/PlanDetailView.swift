//
//  PlanDetailView.swift
//  puctee
//
//  Created by kj on 5/10/25.
//

import SwiftUI
import MapKit

struct PlanDetailView: View {
  /// Initialize with an existing Plan model or ID
  private let plan: Plan?
  private let planId: Int?
  
  @State private var loadedPlan: Plan?
  @State private var isLoading: Bool = false
  @State private var loadError: String?
  @State private var isPresentingDeleteConfirmation = false
  @State private var showPenaltyApprovalSheet = false
  @State private var penaltyStatus: Penalty.Status?
  @State private var penaltyApprovals: [PenaltyApprovalRequestResponse]?
  
  @State private var isPresentingEdit = false
  @State private var showReportSheet = false
  @Environment(\.planManager) private var planManager
  @Environment(\.dismiss) private var dismiss
  
  /// Initialize with a Plan instance
  init(plan: Plan) {
    self.plan = plan
    self.planId = nil
  }
  /// Initialize with a Plan ID
  init(id: String) {
    self.plan = nil
    self.planId = Int(id)
  }
  
  private var showActionButton: Bool {
    penaltyStatus == .required || penaltyStatus == .pendingApproval
  }
  
  var body: some View {
    Group {
      if let planData = loadedPlan {
        detailContent(for: planData)
      } else if let planData = plan {
        detailContent(for: planData)
          .task {
            self.penaltyStatus = await planManager.fetchCurrentUserPenaltyStatus(planId: planData.id)
          }
      } else if isLoading {
        VStack {
          ProgressView("Loading...")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else if let err = loadError {
        VStack(spacing: 16) {
          Text("Failed to load")
            .foregroundColor(.red)
          Text(err)
            .font(.caption)
            .foregroundColor(.secondary)
          Button("Reload") {
            Task { await loadPlan() }
          }
        }
        .padding()
      } else {
        Color.clear
          .task { await loadPlan() }
      }
    }
    .navigationTitle(loadedPlan?.title ?? plan?.title ?? "Plan Details")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      if (plan ?? loadedPlan) != nil {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
          Button {
            // share action
          } label: {
            Image(systemName: "square.and.arrow.up")
          }
          Menu {
            Button {
              isPresentingEdit = true
            } label: {
              Label("Edit", systemImage: "pencil")
            }
            Button {
              showReportSheet = true
            } label: {
              Label("Report Plan", systemImage: "exclamationmark.bubble")
            }
            Button("Delete", role: .destructive) {
              isPresentingDeleteConfirmation = true
            }
          } label: {
            Image(systemName: "ellipsis")
          }
        }
      }
    }
    .alert(
      "Delete this plan?",
      isPresented: $isPresentingDeleteConfirmation
    ) {
      Button("Delete", role: .destructive) {
        Task { await deletePlan() }
      }
      Button("Cancel", role: .cancel) { }
    } message: {
      Text("Once deleted, it cannot be recovered.")
    }
    .fullScreenCover(isPresented: $isPresentingEdit) {
      if let planData = loadedPlan {
        PlanEditorView(plan: planData)
      }
    }
    .sheet(isPresented: $showPenaltyApprovalSheet) {
      PlanPenaltyApprovalRequestView(plan: plan, isPresented: $showPenaltyApprovalSheet)
        .interactiveDismissDisabled()
    }
    .sheet(isPresented: $showReportSheet) {
      if let planData = plan ?? loadedPlan {
        ReportContentSheet(
          contentType: .plan,
          contentId: planData.id,
          reportedUserId: planData.createdBy
        )
      }
    }
  }
  
  @ViewBuilder
  private func detailContent(for plan: Plan) -> some View {
    VStack {
      ScrollView {
        VStack(spacing: 24) {
          // Title + status chip + date + participants
          VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 8) {
              Text(plan.title)
                .font(.title2)
                .fontWeight(.bold)
              Text(plan.status.rawValue.capitalized)
                .font(.caption2)
                .fontWeight(.semibold)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(
                  Capsule()
                    .fill(statusColor(for: plan).opacity(0.2))
                )
                .foregroundColor(statusColor(for: plan))
              Spacer()
            }
            HStack(spacing: 8) {
              Label {
                Text(formattedDateText(from: plan.startTime))
              } icon: {
                Image(systemName: "calendar")
              }
              .font(.subheadline)
              Spacer()
              ParticipantsStackView(for: plan.participants)
            }
            .foregroundColor(.secondary)
          }
          .padding(4)
          
          PlanDetailLocationCard(plan: plan)
          
          // Penalty
          PlanDetailPenaltySection(plan: plan, penaltyStatus: $penaltyStatus)
        }
        .padding(.top)
        .padding(.horizontal)
      }
      
      // action button to send penalty approval
      if showActionButton, let penaltyStatus = penaltyStatus {
        PlanDetailActionButtonSection(
          showPenaltyApprovalSheet: $showPenaltyApprovalSheet,
          penaltyStatus: penaltyStatus
        )
      }
    }
  }
  
  private func loadPlan() async {
    guard let id = planId ?? plan?.id else { return }
    isLoading = true
    loadError = nil
    
    loadedPlan = await planManager.fetchPlan(id: id)
    isLoading = false
    
    // load penalty status if plan was loaded
    self.penaltyStatus = await planManager.fetchCurrentUserPenaltyStatus(planId: id)
  }
  
  private func deletePlan() async {
    guard let id = planId ?? plan?.id else { return }
    await planManager.deletePlan(id: id)
    dismiss()
  }
  
  private func statusColor(for plan: Plan) -> Color {
    switch plan.status.rawValue.lowercased() {
      case "upcoming": return .green
      case "completed": return .gray
      case "canceled":  return .red
      default:          return .accentColor
    }
  }
}

struct PlanDetailView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      PlanDetailView(plan: SampleData.planPicnic)
    }
    NavigationStack {
      PlanDetailView(id: "40")
    }
  }
}
