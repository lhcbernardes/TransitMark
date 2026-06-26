//
//  NotificationScheduler.swift
//  TransitMark
//

import Foundation
import UserNotifications

@MainActor
final class NotificationScheduler {
    static let shared = NotificationScheduler()

    private let flightLeadTime: TimeInterval = 4 * 3600
    private let checkInLeadTime: TimeInterval = 24 * 3600
    private let activityLeadTime: TimeInterval = 30 * 60

    private init() {}

    func requestPermissionIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .badge, .sound])
    }

    func refresh(trip: Trip) {
        let center = UNUserNotificationCenter.current()
        let prefix = identifierPrefix(for: trip)
        center.getPendingNotificationRequests { requests in
            let toRemove = requests
                .map(\.identifier)
                .filter { $0.hasPrefix(prefix) }
            center.removePendingNotificationRequests(withIdentifiers: toRemove)
            Task { @MainActor in
                self.scheduleAll(for: trip)
            }
        }
    }

    func cancel(trip: Trip) {
        let center = UNUserNotificationCenter.current()
        let prefix = identifierPrefix(for: trip)
        center.getPendingNotificationRequests { requests in
            let toRemove = requests
                .map(\.identifier)
                .filter { $0.hasPrefix(prefix) }
            center.removePendingNotificationRequests(withIdentifiers: toRemove)
        }
    }

    private func scheduleAll(for trip: Trip) {
        for flight in trip.flights {
            schedule(
                triggerAt: flight.scheduledDeparture.addingTimeInterval(-flightLeadTime),
                title: String(localized: "Voo em 4h"),
                body: "\(flight.displayCode) · \(flight.originAirportCode) → \(flight.destinationAirportCode)",
                identifier: identifier(for: trip, kind: "flight", id: flight.id)
            )
            schedule(
                triggerAt: flight.scheduledDeparture.addingTimeInterval(-checkInLeadTime),
                title: String(localized: "Check-in disponível"),
                body: "\(flight.displayCode) · \(flight.originAirportCode) → \(flight.destinationAirportCode)",
                identifier: identifier(for: trip, kind: "checkin", id: flight.id)
            )
        }

        for activity in trip.activities {
            schedule(
                triggerAt: activity.startsAt.addingTimeInterval(-activityLeadTime),
                title: String(localized: "Em 30 min"),
                body: activity.title,
                identifier: identifier(for: trip, kind: "activity", id: activity.id)
            )
        }

        for stay in trip.stays {
            schedule(
                triggerAt: stay.checkIn,
                title: String(localized: "Hora do check-in"),
                body: stay.name,
                identifier: identifier(for: trip, kind: "stay", id: stay.id)
            )
        }
    }

    private func schedule(triggerAt date: Date, title: String, body: String, identifier: String) {
        guard date > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: date.timeIntervalSinceNow,
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func identifierPrefix(for trip: Trip) -> String {
        "trip-\(trip.id)-"
    }

    private func identifier(for trip: Trip, kind: String, id: UUID) -> String {
        "\(identifierPrefix(for: trip))\(kind)-\(id)"
    }
}
