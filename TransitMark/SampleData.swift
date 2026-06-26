//
//  SampleData.swift
//  TransitMark
//

import Foundation

#if DEBUG
enum SampleData {
    static func preBoardingFlight(now: Date = .now) -> Flight {
        let flight = Flight(
            airline: "JAL",
            flightNumber: "JL 8390",
            originAirportCode: "GRU",
            originAirportName: "São Paulo Guarulhos",
            originTimeZoneID: "America/Sao_Paulo",
            scheduledDeparture: now.addingTimeInterval(3 * 3600),
            destinationAirportCode: "HND",
            destinationAirportName: "Tóquio Haneda",
            destinationTimeZoneID: "Asia/Tokyo",
            scheduledArrival: now.addingTimeInterval(28 * 3600)
        )
        flight.terminal = "3"
        flight.gate = "B24"
        flight.seat = "14A"
        flight.confirmationCode = "JL8XK2"
        flight.passengerName = "LEANDRO BERNARDES"
        flight.originLatitude = -23.4356
        flight.originLongitude = -46.4731
        flight.destinationLatitude = 35.5494
        flight.destinationLongitude = 139.7798
        return flight
    }

    static func tokyoStay(now: Date = .now) -> Stay {
        let stay = Stay(
            name: "Park Hyatt Tokyo",
            address: "3-7-1-2 Nishi-Shinjuku, Shinjuku, Tóquio 163-1055, Japão",
            timeZoneID: "Asia/Tokyo",
            checkIn: now.addingTimeInterval(30 * 3600),
            checkOut: now.addingTimeInterval(30 * 3600 + 4 * 86_400)
        )
        stay.confirmationCode = "HY-7290183"
        stay.accessCode = "5821"
        stay.latitude = 35.6859
        stay.longitude = 139.6906
        return stay
    }

    static func tokyoDayItems(now: Date = .now) -> [any TripTimelineItem] {
        let lunch = Activity(
            title: "Almoço no Sukiyabashi Jiro",
            timeZoneID: "Asia/Tokyo",
            startsAt: now.addingTimeInterval(2 * 3600),
            endsAt: now.addingTimeInterval(3 * 3600)
        )
        lunch.locationName = "Sukiyabashi Jiro"
        lunch.address = "4-2-15 Ginza, Chuo, Tóquio"

        let museum = Activity(
            title: "Museu teamLab Borderless",
            timeZoneID: "Asia/Tokyo",
            startsAt: now.addingTimeInterval(5 * 3600),
            endsAt: now.addingTimeInterval(7 * 3600)
        )
        museum.locationName = "teamLab Borderless"
        museum.address = "Azabudai Hills, Tóquio"

        let dinner = Activity(
            title: "Jantar com a equipe",
            timeZoneID: "Asia/Tokyo",
            startsAt: now.addingTimeInterval(9 * 3600),
            endsAt: now.addingTimeInterval(11 * 3600)
        )
        dinner.locationName = "Narisawa"
        dinner.address = "2-6-15 Minami Aoyama, Tóquio"

        return [lunch, museum, dinner]
    }
}
#endif
