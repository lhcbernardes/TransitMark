//
//  TripArchiveTests.swift
//  TransitMarkTests
//

import Testing
import Foundation
@testable import TransitMark

@Suite("Trip archiving")
struct TripArchiveTests {

    @Test func notArchivedWhenNoEvents() {
        let trip = Trip(name: "Empty")
        #expect(!trip.isArchived)
    }

    @Test func notArchivedWhenRecentEvent() {
        let trip = Trip(name: "Recent")
        let activity = Activity(
            title: "Recent",
            timeZoneID: "UTC",
            startsAt: .now.addingTimeInterval(-3600),
            endsAt: .now.addingTimeInterval(-1800)
        )
        activity.trip = trip
        trip.activities.append(activity)
        #expect(!trip.isArchived)
    }

    @Test func archivedWhenOldEvent() {
        let trip = Trip(name: "Old")
        let activity = Activity(
            title: "Past",
            timeZoneID: "UTC",
            startsAt: .now.addingTimeInterval(-30 * 86_400),
            endsAt: .now.addingTimeInterval(-30 * 86_400 + 3600)
        )
        activity.trip = trip
        trip.activities.append(activity)
        #expect(trip.isArchived)
    }

    @Test func notArchivedRightAtThreshold() {
        let trip = Trip(name: "Edge")
        let almost = Calendar.current.date(
            byAdding: .day,
            value: -(Trip.archiveThresholdDays - 1),
            to: .now
        ) ?? .now
        let activity = Activity(
            title: "Edge",
            timeZoneID: "UTC",
            startsAt: almost.addingTimeInterval(-3600),
            endsAt: almost
        )
        activity.trip = trip
        trip.activities.append(activity)
        #expect(!trip.isArchived)
    }

    @Test func notArchivedIfFutureEventExists() {
        let trip = Trip(name: "Mixed")
        let past = Activity(
            title: "Past",
            timeZoneID: "UTC",
            startsAt: .now.addingTimeInterval(-30 * 86_400),
            endsAt: .now.addingTimeInterval(-30 * 86_400 + 3600)
        )
        past.trip = trip
        let future = Activity(
            title: "Future",
            timeZoneID: "UTC",
            startsAt: .now.addingTimeInterval(86_400),
            endsAt: .now.addingTimeInterval(90_000)
        )
        future.trip = trip
        trip.activities.append(past)
        trip.activities.append(future)
        #expect(!trip.isArchived)
    }
}
