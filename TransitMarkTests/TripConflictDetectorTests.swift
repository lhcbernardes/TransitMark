//
//  TripConflictDetectorTests.swift
//  TransitMarkTests
//

import Testing
import Foundation
@testable import TransitMark

@Suite("TripConflictDetector")
struct TripConflictDetectorTests {

    private let reference = Date(timeIntervalSince1970: 1_750_000_000)

    private func makeTrip(
        flights: [(departureOffset: TimeInterval, arrivalOffset: TimeInterval)] = [],
        activities: [(startOffset: TimeInterval, endOffset: TimeInterval)] = []
    ) -> Trip {
        let trip = Trip(name: "Test")
        for spec in flights {
            let flight = Flight(
                airline: "X",
                flightNumber: "X1",
                originAirportCode: "AAA",
                originAirportName: "A",
                originTimeZoneID: "UTC",
                scheduledDeparture: reference.addingTimeInterval(spec.departureOffset),
                destinationAirportCode: "BBB",
                destinationAirportName: "B",
                destinationTimeZoneID: "UTC",
                scheduledArrival: reference.addingTimeInterval(spec.arrivalOffset)
            )
            flight.trip = trip
            trip.flights.append(flight)
        }
        for spec in activities {
            let activity = Activity(
                title: "Activity",
                timeZoneID: "UTC",
                startsAt: reference.addingTimeInterval(spec.startOffset),
                endsAt: reference.addingTimeInterval(spec.endOffset)
            )
            activity.trip = trip
            trip.activities.append(activity)
        }
        return trip
    }

    @Test func returnsEmptyWhenNoOverlap() {
        let trip = makeTrip(activities: [(0, 3600)])
        let conflicts = TripConflictDetector.conflicts(
            with: reference.addingTimeInterval(7200)..<reference.addingTimeInterval(10800),
            in: trip
        )
        #expect(conflicts.isEmpty)
    }

    @Test func detectsOverlappingActivity() {
        let trip = makeTrip(activities: [(0, 3600)])
        let conflicts = TripConflictDetector.conflicts(
            with: reference.addingTimeInterval(1800)..<reference.addingTimeInterval(5400),
            in: trip
        )
        #expect(conflicts.count == 1)
    }

    @Test func detectsOverlappingFlight() {
        let trip = makeTrip(flights: [(0, 10800)])
        let conflicts = TripConflictDetector.conflicts(
            with: reference.addingTimeInterval(7200)..<reference.addingTimeInterval(14400),
            in: trip
        )
        #expect(conflicts.count == 1)
    }

    @Test func excludesItemById() {
        let trip = makeTrip(activities: [(0, 3600)])
        let activityID = trip.activities[0].id
        let conflicts = TripConflictDetector.conflicts(
            with: reference.addingTimeInterval(0)..<reference.addingTimeInterval(3600),
            in: trip,
            excluding: activityID
        )
        #expect(conflicts.isEmpty)
    }

    @Test func ignoresStaysIntentionally() {
        let trip = Trip(name: "Test")
        let stay = Stay(
            name: "Hotel",
            address: "",
            timeZoneID: "UTC",
            checkIn: reference,
            checkOut: reference.addingTimeInterval(86_400)
        )
        stay.trip = trip
        trip.stays.append(stay)
        let conflicts = TripConflictDetector.conflicts(
            with: reference.addingTimeInterval(0)..<reference.addingTimeInterval(3600),
            in: trip
        )
        #expect(conflicts.isEmpty)
    }

    @Test func returnsEmptyForInvalidRange() {
        let trip = makeTrip(activities: [(0, 3600)])
        let conflicts = TripConflictDetector.conflicts(
            with: reference.addingTimeInterval(3600)..<reference.addingTimeInterval(3600),
            in: trip
        )
        #expect(conflicts.isEmpty)
    }
}
