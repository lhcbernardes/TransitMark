//
//  Flight.swift
//  TransitMark
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class Flight {
    var id: UUID = UUID()
    var trip: Trip?

    var airline: String = ""
    var flightNumber: String = ""
    var confirmationCode: String?
    var passengerName: String?
    var seat: String?

    var originAirportCode: String = ""
    var originAirportName: String = ""
    var originLatitude: Double?
    var originLongitude: Double?
    var originTimeZoneID: String = "UTC"
    var scheduledDeparture: Date = Date()

    var destinationAirportCode: String = ""
    var destinationAirportName: String = ""
    var destinationLatitude: Double?
    var destinationLongitude: Double?
    var destinationTimeZoneID: String = "UTC"
    var scheduledArrival: Date = Date()

    var terminal: String?
    var gate: String?
    var notes: String?

    init(
        id: UUID = UUID(),
        airline: String,
        flightNumber: String,
        originAirportCode: String,
        originAirportName: String,
        originTimeZoneID: String,
        scheduledDeparture: Date,
        destinationAirportCode: String,
        destinationAirportName: String,
        destinationTimeZoneID: String,
        scheduledArrival: Date
    ) {
        self.id = id
        self.airline = airline
        self.flightNumber = flightNumber
        self.originAirportCode = originAirportCode
        self.originAirportName = originAirportName
        self.originTimeZoneID = originTimeZoneID
        self.scheduledDeparture = scheduledDeparture
        self.destinationAirportCode = destinationAirportCode
        self.destinationAirportName = destinationAirportName
        self.destinationTimeZoneID = destinationTimeZoneID
        self.scheduledArrival = scheduledArrival
    }

    var originTimeZone: TimeZone { TimeZone(identifier: originTimeZoneID) ?? .gmt }
    var destinationTimeZone: TimeZone { TimeZone(identifier: destinationTimeZoneID) ?? .gmt }

    var destinationCoordinate: CLLocationCoordinate2D? {
        guard let lat = destinationLatitude, let lon = destinationLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }

    var displayCode: String {
        let number = flightNumber.trimmingCharacters(in: .whitespaces)
        if number.first?.isLetter == true { return number }
        return "\(airline) · \(number)"
    }

    static func resolveAirportCode(existing: String, from name: String) -> String {
        let trimmedExisting = existing.trimmingCharacters(in: .whitespaces).uppercased()
        if !trimmedExisting.isEmpty {
            return trimmedExisting
        }
        if let range = name.range(of: #"\(([A-Z]{3})\)"#, options: .regularExpression) {
            return name[range]
                .trimmingCharacters(in: CharacterSet(charactersIn: "()"))
        }
        return name
            .split(separator: " ")
            .compactMap { word in word.first(where: { $0.isLetter }) }
            .prefix(3)
            .map { String($0).uppercased() }
            .joined()
    }
}

extension Flight: TripTimelineItem {
    var startDate: Date { scheduledDeparture }
    var endDate: Date { scheduledArrival }
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = originLatitude, let lon = originLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    var displayTitle: String { displayCode }
    var displaySubtitle: String? { "\(originAirportCode) → \(destinationAirportCode)" }
    var displaySymbol: String { "airplane.departure" }
    var timeZone: TimeZone { originTimeZone }
}
