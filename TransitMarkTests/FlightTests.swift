//
//  FlightTests.swift
//  TransitMarkTests
//

import Testing
import Foundation
@testable import TransitMark

@Suite("Flight derivers")
struct FlightTests {

    private func makeFlight() -> Flight {
        Flight(
            airline: "",
            flightNumber: "",
            originAirportCode: "",
            originAirportName: "",
            originTimeZoneID: "UTC",
            scheduledDeparture: .now,
            destinationAirportCode: "",
            destinationAirportName: "",
            destinationTimeZoneID: "UTC",
            scheduledArrival: .now
        )
    }

    @Test func displayCodeReturnsFlightNumberAloneWhenItStartsWithLetter() {
        let flight = makeFlight()
        flight.airline = "JAL"
        flight.flightNumber = "JL 8390"
        #expect(flight.displayCode == "JL 8390")
    }

    @Test func displayCodePrefixesAirlineWhenNumberStartsWithDigit() {
        let flight = makeFlight()
        flight.airline = "GOL"
        flight.flightNumber = "1602"
        #expect(flight.displayCode == "GOL · 1602")
    }

    @Test func displayCodeTrimsWhitespaceInFlightNumber() {
        let flight = makeFlight()
        flight.airline = "AA"
        flight.flightNumber = "  100  "
        #expect(flight.displayCode == "AA · 100")
    }

    @Test func airportCodeResolverPreservesExistingUppercased() {
        let result = Flight.resolveAirportCode(existing: "gru", from: "Whatever Airport (XYZ)")
        #expect(result == "GRU")
    }

    @Test func airportCodeResolverExtractsIATAFromParens() {
        let result = Flight.resolveAirportCode(existing: "", from: "Aeroporto Internacional de Guarulhos (GRU)")
        #expect(result == "GRU")
    }

    @Test func airportCodeResolverFallsBackToInitialsWhenNoParens() {
        let result = Flight.resolveAirportCode(existing: "", from: "Tokyo Haneda Airport")
        #expect(result == "THA")
    }

    @Test func airportCodeResolverHandlesEmptyName() {
        let result = Flight.resolveAirportCode(existing: "", from: "")
        #expect(result == "")
    }

    @Test func airportCodeResolverIgnoresLowercaseParens() {
        let result = Flight.resolveAirportCode(existing: "", from: "Place (gr) Airport")
        #expect(result == "PGA")
    }
}
