//
//  BoardingPassImporter.swift
//  TransitMark
//

import Foundation
import FoundationModels

@Generable(description: "Structured flight information extracted from a boarding pass or travel itinerary")
struct ExtractedBoardingPass {
    @Guide(description: "Airline company name, e.g. 'LATAM Airlines', 'GOL', 'Azul'")
    var airline: String

    @Guide(description: "Flight number including airline prefix when present, e.g. 'LA3056', 'G3 1234'")
    var flightNumber: String

    @Guide(description: "IATA 3-letter departure airport code, e.g. 'GRU', 'CGH', 'BSB'")
    var originCode: String

    @Guide(description: "Departure airport or city name")
    var originName: String

    @Guide(description: "IATA 3-letter arrival airport code, e.g. 'NRT', 'LHR', 'CDG'")
    var destinationCode: String

    @Guide(description: "Arrival airport or city name")
    var destinationName: String

    @Guide(description: "Departure date and time in format YYYY-MM-DDTHH:mm. Infer year from context.")
    var departureDateTimeISO: String

    @Guide(description: "Arrival date and time in format YYYY-MM-DDTHH:mm. Infer year from context.")
    var arrivalDateTimeISO: String

    @Guide(description: "Passenger seat number such as '23A'. Empty string if absent.")
    var seat: String

    @Guide(description: "Boarding gate such as 'B12'. Empty string if absent.")
    var gate: String

    @Guide(description: "Booking confirmation or PNR code such as 'XKZPQ8'. Empty string if absent.")
    var confirmationCode: String

    @Guide(description: "Passenger full name as printed. Empty string if absent.")
    var passengerName: String
}

@MainActor
enum BoardingPassImporter {

    static func extract(from text: String) async throws -> ExtractedBoardingPass {
        let session = LanguageModelSession(instructions: """
            Extract structured flight information from boarding pass or travel document text.
            Use ISO 8601 format for dates and times: YYYY-MM-DDTHH:mm.
            Infer the year from context; if unclear, use the current year.
            Leave fields as empty strings when information is clearly absent.
            """)
        let response = try await session.respond(to: text, generating: ExtractedBoardingPass.self)
        return response.content
    }

    static func toFlight(from pass: ExtractedBoardingPass, trip: Trip) -> Flight {
        let departure = parseDate(pass.departureDateTimeISO) ?? .now
        let arrival = parseDate(pass.arrivalDateTimeISO) ?? departure.addingTimeInterval(3600)

        let flight = Flight(
            airline: pass.airline,
            flightNumber: pass.flightNumber,
            originAirportCode: pass.originCode.uppercased(),
            originAirportName: pass.originName,
            originTimeZoneID: TimeZone.current.identifier,
            scheduledDeparture: departure,
            destinationAirportCode: pass.destinationCode.uppercased(),
            destinationAirportName: pass.destinationName,
            destinationTimeZoneID: TimeZone.current.identifier,
            scheduledArrival: arrival
        )
        flight.seat = normalize(pass.seat)
        flight.gate = normalize(pass.gate)
        flight.confirmationCode = normalize(pass.confirmationCode)
        flight.passengerName = normalize(pass.passengerName)
        flight.trip = trip
        return flight
    }

    static func parseDate(_ str: String) -> Date? {
        let trimmed = str.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for fmt in ["yyyy-MM-dd'T'HH:mm", "yyyy-MM-dd HH:mm", "dd/MM/yyyy HH:mm"] {
            formatter.dateFormat = fmt
            if let date = formatter.date(from: trimmed) { return date }
        }
        return nil
    }

    private static func normalize(_ s: String) -> String? {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
