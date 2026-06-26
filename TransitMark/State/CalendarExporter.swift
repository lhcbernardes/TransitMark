//
//  CalendarExporter.swift
//  TransitMark
//

import Foundation
import EventKit

enum CalendarExportError: Error {
    case permissionDenied
    case noDefaultCalendar
}

@MainActor
enum CalendarExporter {
    static func export(trip: Trip) async throws -> Int {
        let store = EKEventStore()
        let granted = try await store.requestWriteOnlyAccessToEvents()
        guard granted else { throw CalendarExportError.permissionDenied }
        guard let calendar = store.defaultCalendarForNewEvents else {
            throw CalendarExportError.noDefaultCalendar
        }

        var count = 0

        for flight in trip.flights {
            let event = EKEvent(eventStore: store)
            event.calendar = calendar
            event.title = "✈︎ \(flight.displayCode) · \(flight.originAirportCode) → \(flight.destinationAirportCode)"
            event.startDate = flight.scheduledDeparture
            event.endDate = flight.scheduledArrival
            event.timeZone = flight.originTimeZone
            event.location = flight.originAirportName
            event.notes = flight.notes
            try store.save(event, span: .thisEvent)
            count += 1
        }

        for stay in trip.stays {
            let event = EKEvent(eventStore: store)
            event.calendar = calendar
            event.title = "🛏 \(stay.name)"
            event.startDate = stay.checkIn
            event.endDate = stay.checkOut
            event.timeZone = stay.timeZone
            event.location = stay.address.isEmpty ? nil : stay.address
            event.notes = stay.notes
            try store.save(event, span: .thisEvent)
            count += 1
        }

        for activity in trip.activities {
            let event = EKEvent(eventStore: store)
            event.calendar = calendar
            event.title = activity.title
            event.startDate = activity.startsAt
            event.endDate = activity.endsAt
            event.timeZone = activity.timeZone
            event.location = activity.locationName ?? activity.address
            event.notes = activity.notes
            try store.save(event, span: .thisEvent)
            count += 1
        }

        return count
    }
}
