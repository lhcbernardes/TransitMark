//
//  WidgetSnapshotWriter.swift
//  TransitMark
//

import CoreLocation
import Foundation
import WidgetKit

@MainActor
enum WidgetSnapshotWriter {
    static func update(trips: [Trip]) {
        let active = trips.filter { !$0.isArchived }
        let allItems = active.flatMap(\.timelineItems).sorted { $0.startDate < $1.startDate }
        let next = allItems.first { $0.startDate > .now }

        if let next {
            let coord = next.coordinate
            let snapshot = WidgetSnapshot(
                kind: kind(for: next),
                title: next.displayTitle,
                subtitle: next.displaySubtitle,
                startDate: next.startDate,
                endDate: next.endDate,
                timeZoneIdentifier: next.timeZone.identifier,
                latitude: coord?.latitude,
                longitude: coord?.longitude
            )
            WidgetSnapshot.save(snapshot)
        } else {
            WidgetSnapshot.save(nil)
        }

        WidgetCenter.shared.reloadAllTimelines()
    }

    private static func kind(for item: any TripTimelineItem) -> WidgetSnapshot.Kind {
        if item is Flight { return .flight }
        if item is Stay { return .stay }
        return .activity
    }
}
