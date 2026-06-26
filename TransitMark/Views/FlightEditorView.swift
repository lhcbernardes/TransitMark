//
//  FlightEditorView.swift
//  TransitMark
//

import SwiftUI
import SwiftData
import MapKit

struct FlightEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let trip: Trip
    let flight: Flight?

    @State private var airline: String
    @State private var flightNumber: String
    @State private var originCode: String
    @State private var originPlace: SelectedPlace?
    @State private var destinationCode: String
    @State private var destinationPlace: SelectedPlace?
    @State private var scheduledDeparture: Date
    @State private var scheduledArrival: Date
    @State private var terminal: String
    @State private var gate: String
    @State private var seat: String
    @State private var confirmationCode: String
    @State private var passengerName: String
    @State private var notes: String

    init(trip: Trip, flight: Flight? = nil, connectingFrom previous: Flight? = nil) {
        self.trip = trip
        self.flight = flight

        if let flight {
            _airline = State(initialValue: flight.airline)
            _flightNumber = State(initialValue: flight.flightNumber)
            _originCode = State(initialValue: flight.originAirportCode)
            _destinationCode = State(initialValue: flight.destinationAirportCode)
            _scheduledDeparture = State(initialValue: flight.scheduledDeparture)
            _scheduledArrival = State(initialValue: flight.scheduledArrival)
            _terminal = State(initialValue: flight.terminal ?? "")
            _gate = State(initialValue: flight.gate ?? "")
            _seat = State(initialValue: flight.seat ?? "")
            _confirmationCode = State(initialValue: flight.confirmationCode ?? "")
            _passengerName = State(initialValue: flight.passengerName ?? "")
            _notes = State(initialValue: flight.notes ?? "")

            if let lat = flight.originLatitude, let lon = flight.originLongitude {
                _originPlace = State(initialValue: SelectedPlace(
                    name: flight.originAirportName,
                    address: "",
                    coordinate: .init(latitude: lat, longitude: lon),
                    timeZoneID: flight.originTimeZoneID
                ))
            } else {
                _originPlace = State(initialValue: nil)
            }
            if let lat = flight.destinationLatitude, let lon = flight.destinationLongitude {
                _destinationPlace = State(initialValue: SelectedPlace(
                    name: flight.destinationAirportName,
                    address: "",
                    coordinate: .init(latitude: lat, longitude: lon),
                    timeZoneID: flight.destinationTimeZoneID
                ))
            } else {
                _destinationPlace = State(initialValue: nil)
            }
        } else if let previous {
            let departure = previous.scheduledArrival.addingTimeInterval(2 * 3600)
            _airline = State(initialValue: previous.airline)
            _flightNumber = State(initialValue: "")
            _originCode = State(initialValue: previous.destinationAirportCode)
            _destinationCode = State(initialValue: "")
            _scheduledDeparture = State(initialValue: departure)
            _scheduledArrival = State(initialValue: departure.addingTimeInterval(3 * 3600))
            _terminal = State(initialValue: "")
            _gate = State(initialValue: "")
            _seat = State(initialValue: "")
            _confirmationCode = State(initialValue: previous.confirmationCode ?? "")
            _passengerName = State(initialValue: previous.passengerName ?? "")
            _notes = State(initialValue: "")

            if let lat = previous.destinationLatitude, let lon = previous.destinationLongitude {
                _originPlace = State(initialValue: SelectedPlace(
                    name: previous.destinationAirportName,
                    address: "",
                    coordinate: .init(latitude: lat, longitude: lon),
                    timeZoneID: previous.destinationTimeZoneID
                ))
            } else {
                _originPlace = State(initialValue: nil)
            }
            _destinationPlace = State(initialValue: nil)
        } else {
            let calendar = Calendar.current
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: .now) ?? .now
            let departure = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: tomorrow) ?? tomorrow
            _airline = State(initialValue: "")
            _flightNumber = State(initialValue: "")
            _originCode = State(initialValue: "")
            _destinationCode = State(initialValue: "")
            _scheduledDeparture = State(initialValue: departure)
            _scheduledArrival = State(initialValue: departure.addingTimeInterval(3 * 3600))
            _terminal = State(initialValue: "")
            _gate = State(initialValue: "")
            _seat = State(initialValue: "")
            _confirmationCode = State(initialValue: "")
            _passengerName = State(initialValue: "")
            _notes = State(initialValue: "")
            _originPlace = State(initialValue: nil)
            _destinationPlace = State(initialValue: nil)
        }
    }

    private var isEditing: Bool { flight != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Voo") {
                    TextField("Companhia (ex: JAL)", text: $airline)
                    TextField("Número do voo (ex: JL 8390)", text: $flightNumber)
                }

                PlacePickerSection(
                    title: "Aeroporto de origem",
                    searchPlaceholder: "Buscar aeroporto",
                    highlightedCategories: [.airport],
                    selection: $originPlace
                )

                PlacePickerSection(
                    title: "Aeroporto de destino",
                    searchPlaceholder: "Buscar aeroporto",
                    highlightedCategories: [.airport],
                    selection: $destinationPlace
                )

                Section("Horários") {
                    DatePicker("Partida", selection: $scheduledDeparture)
                    DatePicker("Chegada", selection: $scheduledArrival, in: scheduledDeparture...)
                }

                conflictSection

                Section("Detalhes (opcional)") {
                    TextField("Terminal", text: $terminal)
                    TextField("Portão", text: $gate)
                    TextField("Assento", text: $seat)
                    TextField("Código da reserva", text: $confirmationCode)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                    TextField("Nome do passageiro", text: $passengerName)
                        .textInputAutocapitalization(.characters)
                }
                Section("Anotações") {
                    TextField("Opcional", text: $notes, axis: .vertical)
                        .lineLimit(2...6)
                }
            }
            .navigationTitle(isEditing ? "Editar voo" : "Novo voo")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: originPlace) { _, _ in originCode = "" }
            .onChange(of: destinationPlace) { _, _ in destinationCode = "" }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") { save() }
                        .disabled(!canSave)
                }
            }
        }
    }

    private var canSave: Bool {
        !airline.trimmingCharacters(in: .whitespaces).isEmpty
        && !flightNumber.trimmingCharacters(in: .whitespaces).isEmpty
        && originPlace != nil
        && destinationPlace != nil
        && scheduledArrival > scheduledDeparture
    }

    private var conflicts: [any TripTimelineItem] {
        TripConflictDetector.conflicts(
            with: scheduledDeparture..<scheduledArrival,
            in: trip,
            excluding: flight?.id
        )
    }

    @ViewBuilder
    private var conflictSection: some View {
        if !conflicts.isEmpty {
            Section {
                ForEach(conflicts, id: \.id) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.displayTitle)
                                .font(.system(.body, design: .rounded, weight: .medium))
                            Text(conflictTimeRange(of: item))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                }
            } header: {
                Text("Conflitos")
            }
        }
    }

    private func conflictTimeRange(of item: any TripTimelineItem) -> String {
        var style = Date.FormatStyle.dateTime.weekday(.short).hour().minute()
        style.timeZone = item.timeZone
        return "\(item.startDate.formatted(style)) – \(item.endDate.formatted(style))"
    }

    private func save() {
        let trimmedAirline = airline.trimmingCharacters(in: .whitespaces)
        let trimmedNumber = flightNumber.trimmingCharacters(in: .whitespaces)

        let originName = originPlace?.name ?? ""
        let originTZ = originPlace?.timeZoneID ?? TimeZone.current.identifier
        let destName = destinationPlace?.name ?? ""
        let destTZ = destinationPlace?.timeZoneID ?? TimeZone.current.identifier

        let trimmedOriginCode = Flight.resolveAirportCode(
            existing: originCode,
            from: originName
        )
        let trimmedDestinationCode = Flight.resolveAirportCode(
            existing: destinationCode,
            from: destName
        )

        if let flight {
            flight.airline = trimmedAirline
            flight.flightNumber = trimmedNumber
            flight.originAirportCode = trimmedOriginCode
            flight.originAirportName = originName
            flight.originTimeZoneID = originTZ
            flight.originLatitude = originPlace?.latitude
            flight.originLongitude = originPlace?.longitude
            flight.destinationAirportCode = trimmedDestinationCode
            flight.destinationAirportName = destName
            flight.destinationTimeZoneID = destTZ
            flight.destinationLatitude = destinationPlace?.latitude
            flight.destinationLongitude = destinationPlace?.longitude
            flight.scheduledDeparture = scheduledDeparture
            flight.scheduledArrival = scheduledArrival
            flight.terminal = normalize(terminal)
            flight.gate = normalize(gate)
            flight.seat = normalize(seat)
            flight.confirmationCode = normalize(confirmationCode)
            flight.passengerName = normalize(passengerName)
            flight.notes = normalize(notes)
        } else {
            let newFlight = Flight(
                airline: trimmedAirline,
                flightNumber: trimmedNumber,
                originAirportCode: trimmedOriginCode,
                originAirportName: originName,
                originTimeZoneID: originTZ,
                scheduledDeparture: scheduledDeparture,
                destinationAirportCode: trimmedDestinationCode,
                destinationAirportName: destName,
                destinationTimeZoneID: destTZ,
                scheduledArrival: scheduledArrival
            )
            newFlight.originLatitude = originPlace?.latitude
            newFlight.originLongitude = originPlace?.longitude
            newFlight.destinationLatitude = destinationPlace?.latitude
            newFlight.destinationLongitude = destinationPlace?.longitude
            newFlight.terminal = normalize(terminal)
            newFlight.gate = normalize(gate)
            newFlight.seat = normalize(seat)
            newFlight.confirmationCode = normalize(confirmationCode)
            newFlight.passengerName = normalize(passengerName)
            newFlight.notes = normalize(notes)
            newFlight.trip = trip
            modelContext.insert(newFlight)
        }
        NotificationScheduler.shared.refresh(trip: trip)
        WidgetSnapshotWriter.update(trips: [trip])
        dismiss()
    }

    private func normalize(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
