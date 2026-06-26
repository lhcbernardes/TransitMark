//
//  BoardingActivityController.swift
//  TransitMark
//
//  Manages the Live Activity lifecycle for the boarding state.
//  Requires NSSupportsLiveActivities = YES in the app target's Info tab (Xcode).
//

import ActivityKit
import Foundation

@MainActor
final class BoardingActivityController {
    static let shared = BoardingActivityController()

    private var activeActivity: ActivityKit.Activity<BoardingActivityAttributes>?
    private var activeFlight: Flight?

    private init() {}

    func handle(_ state: AppState) {
        switch state {
        case .preBoarding(let flight):
            startOrUpdate(for: flight)
        default:
            endIfActive()
        }
    }

    func endIfActive() {
        guard let activity = activeActivity else { return }
        Task { await activity.end(dismissalPolicy: .immediate) }
        activeActivity = nil
        activeFlight = nil
    }

    private func startOrUpdate(for flight: Flight) {
        let contentState = BoardingActivityAttributes.ContentState(
            gate: flight.gate,
            status: String(localized: "No Prazo"),
            scheduledDeparture: flight.scheduledDeparture
        )

        if let existing = activeActivity, activeFlight?.id == flight.id {
            Task { await existing.update(using: contentState) }
            return
        }

        endIfActive()

        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attrs = BoardingActivityAttributes(
            airline: flight.airline,
            flightCode: flight.displayCode,
            originCode: flight.originAirportCode,
            destinationCode: flight.destinationAirportCode
        )

        do {
            activeActivity = try ActivityKit.Activity.request(
                attributes: attrs,
                contentState: contentState,
                pushType: nil
            )
            activeFlight = flight
        } catch {
            // Live Activities disabled or unavailable (simulator, old OS, permission denied)
        }
    }
}
