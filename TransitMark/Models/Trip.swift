//
//  Trip.swift
//  TransitMark
//

import Foundation
import SwiftData

@Model
final class Trip {
    var id: UUID = UUID()
    var name: String = ""
    var createdAt: Date = Date()
    var manuallyArchived: Bool = false

    @Relationship(deleteRule: .cascade, inverse: \Flight.trip)
    var flights: [Flight] = []

    @Relationship(deleteRule: .cascade, inverse: \Stay.trip)
    var stays: [Stay] = []

    @Relationship(deleteRule: .cascade, inverse: \Activity.trip)
    var activities: [Activity] = []

    init(id: UUID = UUID(), name: String, createdAt: Date = .now) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }

    var timelineItems: [any TripTimelineItem] {
        let items: [any TripTimelineItem] =
            flights.map { $0 as any TripTimelineItem } +
            stays.map { $0 as any TripTimelineItem } +
            activities.map { $0 as any TripTimelineItem }
        return items.sorted { $0.startDate < $1.startDate }
    }

    var startDate: Date? { timelineItems.first?.startDate }
    var endDate: Date? { timelineItems.last?.endDate }
}
