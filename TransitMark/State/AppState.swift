//
//  AppState.swift
//  TransitMark
//

import Foundation

enum AppState {
    case idle
    case preBoarding(Flight)
    case inFlight(Flight, destinationStay: Stay?)
    case landing(Flight, destinationStay: Stay?)
    case staying(currentStay: Stay?, upcomingToday: [any TripTimelineItem])
}

extension AppState {
    var isIdle: Bool {
        if case .idle = self { return true }
        return false
    }

    var preBoardingFlight: Flight? {
        if case .preBoarding(let flight) = self { return flight }
        return nil
    }

    var inFlightFlight: Flight? {
        if case .inFlight(let flight, _) = self { return flight }
        return nil
    }

    var inFlightDestinationStay: Stay? {
        if case .inFlight(_, let stay) = self { return stay }
        return nil
    }

    var landingFlight: Flight? {
        if case .landing(let flight, _) = self { return flight }
        return nil
    }

    var landingDestinationStay: Stay? {
        if case .landing(_, let stay) = self { return stay }
        return nil
    }

    var currentStay: Stay? {
        if case .staying(let stay, _) = self { return stay }
        return nil
    }

    var upcomingTodayItems: [any TripTimelineItem] {
        if case .staying(_, let items) = self { return items }
        return []
    }
}
