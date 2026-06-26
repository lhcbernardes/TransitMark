//
//  Stay.swift
//  TransitMark
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class Stay {
    var id: UUID = UUID()
    var trip: Trip?

    var name: String = ""
    var address: String = ""
    var latitude: Double?
    var longitude: Double?
    var timeZoneID: String = "UTC"

    var checkIn: Date = Date()
    var checkOut: Date = Date()

    var confirmationCode: String?
    var accessCode: String?
    var notes: String?

    init(
        id: UUID = UUID(),
        name: String,
        address: String,
        timeZoneID: String,
        checkIn: Date,
        checkOut: Date
    ) {
        self.id = id
        self.name = name
        self.address = address
        self.timeZoneID = timeZoneID
        self.checkIn = checkIn
        self.checkOut = checkOut
    }

    var timeZone: TimeZone { TimeZone(identifier: timeZoneID) ?? .gmt }
}

extension Stay: TripTimelineItem {
    var startDate: Date { checkIn }
    var endDate: Date { checkOut }
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    var displayTitle: String { name }
    var displaySubtitle: String? { address.isEmpty ? nil : address }
    var displaySymbol: String { "bed.double.fill" }
}
