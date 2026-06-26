//
//  CurrentStateResolverTests.swift
//  TransitMarkTests
//

import Testing
import Foundation
@testable import TransitMark

@Suite("CurrentStateResolver")
struct CurrentStateResolverTests {
    let resolver = CurrentStateResolver()
    let referenceDate = Date(timeIntervalSince1970: 1_750_000_000)

    private func makeFlight(
        departureOffset: TimeInterval,
        arrivalOffset: TimeInterval
    ) -> Flight {
        Flight(
            airline: "GOL",
            flightNumber: "G3-1602",
            originAirportCode: "GRU",
            originAirportName: "São Paulo Guarulhos",
            originTimeZoneID: "America/Sao_Paulo",
            scheduledDeparture: referenceDate.addingTimeInterval(departureOffset),
            destinationAirportCode: "GIG",
            destinationAirportName: "Rio de Janeiro Galeão",
            destinationTimeZoneID: "America/Sao_Paulo",
            scheduledArrival: referenceDate.addingTimeInterval(arrivalOffset)
        )
    }

    private func makeStay(
        checkInOffset: TimeInterval,
        checkOutOffset: TimeInterval
    ) -> Stay {
        Stay(
            name: "Hotel Copacabana",
            address: "Av. Atlântica 1702, Rio de Janeiro",
            timeZoneID: "America/Sao_Paulo",
            checkIn: referenceDate.addingTimeInterval(checkInOffset),
            checkOut: referenceDate.addingTimeInterval(checkOutOffset)
        )
    }

    @Test func returnsIdleWhenNothingScheduled() {
        let state = resolver.resolve(flights: [], stays: [], activities: [], now: referenceDate)
        #expect(state.isIdle)
    }

    @Test func returnsPreBoardingThreeHoursBeforeDeparture() {
        let flight = makeFlight(departureOffset: 3 * 3600, arrivalOffset: 5 * 3600)
        let state = resolver.resolve(flights: [flight], stays: [], activities: [], now: referenceDate)
        #expect(state.preBoardingFlight === flight)
    }

    @Test func doesNotReturnPreBoardingMoreThanFourHoursOut() {
        let flight = makeFlight(departureOffset: 5 * 3600, arrivalOffset: 7 * 3600)
        let state = resolver.resolve(flights: [flight], stays: [], activities: [], now: referenceDate)
        #expect(state.preBoardingFlight == nil)
    }

    @Test func returnsInFlightBetweenDepartureAndArrival() {
        let flight = makeFlight(departureOffset: -1800, arrivalOffset: 3600)
        let state = resolver.resolve(flights: [flight], stays: [], activities: [], now: referenceDate)
        #expect(state.inFlightFlight === flight)
    }

    @Test func returnsLandingWithinTwoHoursAfterArrival() {
        let flight = makeFlight(departureOffset: -4 * 3600, arrivalOffset: -3600)
        let state = resolver.resolve(flights: [flight], stays: [], activities: [], now: referenceDate)
        #expect(state.landingFlight === flight)
    }

    @Test func clearsLandingAfterTwoHourWindow() {
        let flight = makeFlight(departureOffset: -6 * 3600, arrivalOffset: -3 * 3600)
        let state = resolver.resolve(flights: [flight], stays: [], activities: [], now: referenceDate)
        #expect(state.landingFlight == nil)
    }

    @Test func preBoardingWinsOverLandingDuringLayover() {
        let arrived = makeFlight(departureOffset: -3 * 3600, arrivalOffset: -1800)
        let next = makeFlight(departureOffset: 2 * 3600, arrivalOffset: 5 * 3600)
        let state = resolver.resolve(
            flights: [arrived, next],
            stays: [],
            activities: [],
            now: referenceDate
        )
        #expect(state.preBoardingFlight === next)
    }

    @Test func inFlightWinsOverEverything() {
        let active = makeFlight(departureOffset: -1800, arrivalOffset: 3600)
        let layoverNext = makeFlight(departureOffset: 4 * 3600, arrivalOffset: 6 * 3600)
        let stay = makeStay(checkInOffset: -86_400, checkOutOffset: 86_400)
        let state = resolver.resolve(
            flights: [active, layoverNext],
            stays: [stay],
            activities: [],
            now: referenceDate
        )
        #expect(state.inFlightFlight === active)
    }

    @Test func returnsStayingWhenInsideStayWindowWithoutFlight() {
        let stay = makeStay(checkInOffset: -3600, checkOutOffset: 3 * 86_400)
        let state = resolver.resolve(flights: [], stays: [stay], activities: [], now: referenceDate)
        #expect(state.currentStay === stay)
    }

    @Test func inFlightCarriesDestinationStayClosestToArrival() {
        let flight = makeFlight(departureOffset: -1800, arrivalOffset: 3600)
        let irrelevant = makeStay(checkInOffset: 14 * 86_400, checkOutOffset: 21 * 86_400)
        let target = makeStay(checkInOffset: 5 * 3600, checkOutOffset: 4 * 86_400)
        let state = resolver.resolve(
            flights: [flight],
            stays: [irrelevant, target],
            activities: [],
            now: referenceDate
        )
        #expect(state.inFlightDestinationStay === target)
    }

    @Test func landingCarriesNilDestinationStayWhenOutOfWindow() {
        let flight = makeFlight(departureOffset: -4 * 3600, arrivalOffset: -3600)
        let farFuture = makeStay(checkInOffset: 30 * 86_400, checkOutOffset: 35 * 86_400)
        let state = resolver.resolve(
            flights: [flight],
            stays: [farFuture],
            activities: [],
            now: referenceDate
        )
        #expect(state.landingDestinationStay == nil)
    }

    @Test func upcomingTodayExcludesPastItems() {
        let pastActivity = Activity(
            title: "Almoço",
            timeZoneID: "America/Sao_Paulo",
            startsAt: referenceDate.addingTimeInterval(-2 * 3600),
            endsAt: referenceDate.addingTimeInterval(-3600)
        )
        let futureActivity = Activity(
            title: "Museu",
            timeZoneID: "America/Sao_Paulo",
            startsAt: referenceDate.addingTimeInterval(3600),
            endsAt: referenceDate.addingTimeInterval(2 * 3600)
        )
        let stay = makeStay(checkInOffset: -86_400, checkOutOffset: 86_400)
        let state = resolver.resolve(
            flights: [],
            stays: [stay],
            activities: [pastActivity, futureActivity],
            now: referenceDate
        )
        let ids = state.upcomingTodayItems.map(\.id)
        #expect(ids.contains(futureActivity.id))
        #expect(!ids.contains(pastActivity.id))
    }
}
