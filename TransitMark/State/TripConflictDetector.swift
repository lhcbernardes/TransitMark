//
//  TripConflictDetector.swift
//  TransitMark
//

import Foundation

enum TripConflictDetector {
    static func conflicts(
        with range: Range<Date>,
        in trip: Trip,
        excluding excludedID: UUID? = nil
    ) -> [any TripTimelineItem] {
        guard range.lowerBound < range.upperBound else { return [] }
        let allItems: [any TripTimelineItem] =
            trip.flights.map { $0 as any TripTimelineItem } +
            trip.activities.map { $0 as any TripTimelineItem }
        return allItems
            .filter { $0.id != excludedID }
            .filter { ($0.startDate..<$0.endDate).overlaps(range) }
            .sorted { $0.startDate < $1.startDate }
    }
}
