//
//  SampleData.swift
//  puctee
//
//  Created by kj on 5/9/25.
//

import Foundation

enum SampleData {
  // MARK: – Users
  static let alice = User(
    id: 1,
    email: "alice@example.com",
    displayName: "Alice T.",
    username: "alice_t",
    profileImageUrl: URL(string: "https://example.com/images/alice.png")
  )
  
  static let bob = User(
    id: 2,
    email: "bob@example.com",
    displayName: "Bob S.",
    username: "bob_s",
    profileImageUrl: nil
  )
  
  static let charlie = User(
    id: 3,
    email: "charlie@example.com",
    displayName: "Charlie Y.",
    username: "charlie_y",
    profileImageUrl: URL(string: "https://example.com/images/charlie.jpg")
  )
  
  static let diana = User(
    id: 4,
    email: "diana@example.com",
    displayName: "Diana S.",
    username: "diana_s",
    profileImageUrl: URL(string: "https://example.com/images/diana.png")
  )
  
  static let allUsers: [User] = [alice, bob, charlie, diana]
  
  // MARK: – Locations
  static let shibuyaCafe = Location(
    name: "Shibuya Café",
    latitude: 35.6618,
    longitude: 139.7041
  )
  static let yoyogiPark = Location(
    name: "Yoyogi Park",
    latitude: 35.6728,
    longitude: 139.6949
  )
  static let roppongiBar = Location(
    name: "Roppongi Bar",
    latitude: 35.6605,
    longitude: 139.7292
  )
  
  // MARK: – Plans
  private static let meetingFormatter: (Int, Int, Int, Int, Int, Int) -> Date = { year, month, day, hour, minute, second in
    var comps = DateComponents()
    comps.timeZone = TimeZone(identifier: "Asia/Tokyo")
    comps.year = year; comps.month = month; comps.day = day
    comps.hour = hour; comps.minute = minute; comps.second = second
    return Calendar.current.date(from: comps)!
  }
  
  static let planKickoff = Plan(
    id: 1001,
    title: "Project Kickoff",
    startTime: meetingFormatter(2025, 5, 20, 14, 30, 0),
    status: .upcoming,
    location: shibuyaCafe,
    createdAt: meetingFormatter(2025, 5, 1, 9, 0, 0),
    updatedAt: nil,
    participants: [alice, bob, charlie, diana],
    penalties: [.init(id: 1, content: "Starbucks Gift Card")]
  )
  
  static let planPicnic = Plan(
    id: 1002,
    title: "Spring Picnic",
    startTime: meetingFormatter(2025, 5, 25, 11, 0, 0),
    status: .ongoing,
    location: yoyogiPark,
    createdAt: meetingFormatter(2025, 5, 5, 10, 15, 0),
    updatedAt: nil,
    participants: [bob, alice, diana],
    penalties: [.init(id: 2, content: "Share bento boxes with everyone")]
  )
  
  static let planNightOut = Plan(
    id: 1003,
    title: "Night Bar Hopping",
    startTime: meetingFormatter(2025, 6, 1, 19, 45, 0),
    status: .upcoming,
    location: roppongiBar,
    createdAt: meetingFormatter(2025, 5, 10, 18, 30, 0),
    updatedAt: nil,
    participants: [charlie, alice, bob, diana],
    penalties: nil
  )
  
  /// List of mock plans
  static let allPlans: [Plan] = [
    planKickoff,
    planPicnic,
    planNightOut
  ]
  
  // MARK: - PlanInvite
  static let mockPlanInvite = PlanInvite(
    id: 5001,
    status: "pending",
    plan: planNightOut
  )
  
  static let dummyParticipantLocations: [LocationShare] = [
    LocationShare(
      id: 1,
      planId: 1,
      userId: 1,
      displayName: "Alice",
      profileImageUrl: "https://source.unsplash.com/random/200x200?portrait&sig=1",
      latitude: 35.6637,    // Center of Shibuya Ward
      longitude: 139.6977,
      createdAt: "2025-09-07T16:00:00Z",
      updatedAt: "2025-09-07T16:00:00Z"
    ),
    LocationShare(
      id: 2,
      planId: 1,
      userId: 2,
      displayName: "Bob",
      profileImageUrl: "https://source.unsplash.com/random/200x200?portrait&sig=2",
      latitude: 35.6650,    // Slightly north
      longitude: 139.6990,
      createdAt: "2025-09-07T16:01:00Z",
      updatedAt: "2025-09-07T16:01:00Z"
    ),
    LocationShare(
      id: 3,
      planId: 1,
      userId: 3,
      displayName: "Charlie",
      profileImageUrl: "https://source.unsplash.com/random/200x200?portrait&sig=3",
      latitude: 35.6625,    // Slightly southwest
      longitude: 139.6960,
      createdAt: "2025-09-07T16:02:00Z",
      updatedAt: "2025-09-07T16:02:00Z"
    ),
    LocationShare(
      id: 4,
      planId: 1,
      userId: 4,
      displayName: "Diana",
      profileImageUrl: "https://source.unsplash.com/random/200x200?portrait&sig=4",
      latitude: 35.6645,    // Slightly northwest
      longitude: 139.6955,
      createdAt: "2025-09-07T16:03:00Z",
      updatedAt: "2025-09-07T16:03:00Z"
    ),
    LocationShare(
      id: 5,
      planId: 1,
      userId: 5,
      displayName: "Ethan",
      profileImageUrl: "https://source.unsplash.com/random/200x200?portrait&sig=5",
      latitude: 35.6628,    // Slightly southeast
      longitude: 139.6995,
      createdAt: "2025-09-07T16:04:00Z",
      updatedAt: "2025-09-07T16:04:00Z"
    )
  ]
}
