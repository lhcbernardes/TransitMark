//
//  SelectedPlaceTests.swift
//  TransitMarkTests
//

import Testing
import Foundation
import CoreLocation
@testable import TransitMark

@Suite("SelectedPlace")
struct SelectedPlaceTests {

    @Test func coordinateAccessorMatchesStoredLatLon() {
        let place = SelectedPlace(
            name: "Park Hyatt",
            address: "3-7-1-2 Shinjuku",
            coordinate: CLLocationCoordinate2D(latitude: 35.6859, longitude: 139.6906),
            timeZoneID: "Asia/Tokyo"
        )
        #expect(place.latitude == 35.6859)
        #expect(place.longitude == 139.6906)
        #expect(place.coordinate.latitude == 35.6859)
        #expect(place.coordinate.longitude == 139.6906)
    }

    @Test func equatableMatchesAllFields() {
        let a = SelectedPlace(
            name: "A",
            address: "X",
            coordinate: .init(latitude: 1, longitude: 2),
            timeZoneID: "UTC"
        )
        let b = SelectedPlace(
            name: "A",
            address: "X",
            coordinate: .init(latitude: 1, longitude: 2),
            timeZoneID: "UTC"
        )
        #expect(a == b)
    }

    @Test func equatableDifferentiatesByCoordinate() {
        let a = SelectedPlace(
            name: "A",
            address: "X",
            coordinate: .init(latitude: 1, longitude: 2),
            timeZoneID: "UTC"
        )
        let b = SelectedPlace(
            name: "A",
            address: "X",
            coordinate: .init(latitude: 1, longitude: 3),
            timeZoneID: "UTC"
        )
        #expect(a != b)
    }

    @Test func equatableDifferentiatesByTimeZone() {
        let a = SelectedPlace(
            name: "A",
            address: "X",
            coordinate: .init(latitude: 1, longitude: 2),
            timeZoneID: "America/Sao_Paulo"
        )
        let b = SelectedPlace(
            name: "A",
            address: "X",
            coordinate: .init(latitude: 1, longitude: 2),
            timeZoneID: "Asia/Tokyo"
        )
        #expect(a != b)
    }
}
