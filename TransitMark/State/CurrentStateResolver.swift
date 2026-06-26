//
//  CurrentStateResolver.swift
//  TransitMark
//

import Foundation

struct CurrentStateResolver {
    static let preBoardingLeadTime: TimeInterval = 4 * 3600
    static let landingTrailingTime: TimeInterval = 2 * 3600
    static let destinationStayMatchWindow: TimeInterval = 24 * 3600
    static let destinationStayEarlyArrivalWindow: TimeInterval = 6 * 3600

    var calendar: Calendar = .current

    func resolve(trips: [Trip], now: Date = .now) -> AppState {
        let active = trips.filter { !$0.isArchived }
        return resolve(
            flights: active.flatMap(\.flights),
            stays: active.flatMap(\.stays),
            activities: active.flatMap(\.activities),
            now: now
        )
    }

    func resolve(
        flights: [Flight],
        stays: [Stay],
        activities: [Activity],
        now: Date = .now
    ) -> AppState {
        if let flight = activeFlight(in: flights, at: now) {
            return .inFlight(flight, destinationStay: destinationStay(forArrivalAt: flight.scheduledArrival, in: stays))
        }

        if let flight = imminentFlight(in: flights, at: now) {
            return .preBoarding(flight)
        }

        if let flight = recentlyArrivedFlight(in: flights, at: now) {
            return .landing(flight, destinationStay: destinationStay(forArrivalAt: flight.scheduledArrival, in: stays))
        }

        let activeStay = activeStay(in: stays, at: now)
        let upcoming = upcomingItemsToday(
            flights: flights,
            stays: stays,
            activities: activities,
            now: now
        )

        if let stay = activeStay {
            return .staying(currentStay: stay, upcomingToday: upcoming)
        }

        return .idle
    }

    private func activeFlight(in flights: [Flight], at now: Date) -> Flight? {
        flights.first { $0.scheduledDeparture <= now && now < $0.scheduledArrival }
    }

    private func imminentFlight(in flights: [Flight], at now: Date) -> Flight? {
        let upcoming = flights
            .filter { now < $0.scheduledDeparture }
            .sorted { $0.scheduledDeparture < $1.scheduledDeparture }
        guard let next = upcoming.first else { return nil }
        let secondsUntilDeparture = next.scheduledDeparture.timeIntervalSince(now)
        guard secondsUntilDeparture <= Self.preBoardingLeadTime else { return nil }
        return next
    }

    private func recentlyArrivedFlight(in flights: [Flight], at now: Date) -> Flight? {
        flights.first {
            $0.scheduledArrival <= now
            && now < $0.scheduledArrival.addingTimeInterval(Self.landingTrailingTime)
        }
    }

    private func activeStay(in stays: [Stay], at now: Date) -> Stay? {
        stays.first { $0.checkIn <= now && now < $0.checkOut }
    }

    private func destinationStay(forArrivalAt arrival: Date, in stays: [Stay]) -> Stay? {
        let earliest = arrival.addingTimeInterval(-Self.destinationStayEarlyArrivalWindow)
        let latest = arrival.addingTimeInterval(Self.destinationStayMatchWindow)
        return stays
            .filter { $0.checkIn >= earliest && $0.checkIn <= latest }
            .min { abs($0.checkIn.timeIntervalSince(arrival)) < abs($1.checkIn.timeIntervalSince(arrival)) }
    }

    private func upcomingItemsToday(
        flights: [Flight],
        stays: [Stay],
        activities: [Activity],
        now: Date
    ) -> [any TripTimelineItem] {
        let startOfDay = calendar.startOfDay(for: now)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }

        let items: [any TripTimelineItem] =
            flights.map { $0 as any TripTimelineItem } +
            stays.map { $0 as any TripTimelineItem } +
            activities.map { $0 as any TripTimelineItem }

        return items
            .filter { $0.endDate > now && $0.startDate < endOfDay }
            .sorted { $0.startDate < $1.startDate }
    }
}
