//
//  Activity.swift
//  TransitMark
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class Activity {
    var id: UUID = UUID()
    var trip: Trip?

    var title: String = ""
    var locationName: String?
    var address: String?
    var latitude: Double?
    var longitude: Double?
    var timeZoneID: String = "UTC"

    var startsAt: Date = Date()
    var endsAt: Date = Date()
    var notes: String?

    init(
        id: UUID = UUID(),
        title: String,
        timeZoneID: String,
        startsAt: Date,
        endsAt: Date
    ) {
        self.id = id
        self.title = title
        self.timeZoneID = timeZoneID
        self.startsAt = startsAt
        self.endsAt = endsAt
    }

    var timeZone: TimeZone { TimeZone(identifier: timeZoneID) ?? .gmt }
}

extension Activity: TripTimelineItem {
    var startDate: Date { startsAt }
    var endDate: Date { endsAt }
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    var displayTitle: String { title }
    var displaySubtitle: String? { locationName ?? address }
    var displaySymbol: String { "calendar" }
}
