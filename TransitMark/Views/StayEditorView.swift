//
//  StayEditorView.swift
//  TransitMark
//

import SwiftUI
import SwiftData
import MapKit

struct StayEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let trip: Trip
    let stay: Stay?

    @State private var name: String
    @State private var checkIn: Date
    @State private var checkOut: Date
    @State private var confirmationCode: String
    @State private var notes: String
    @State private var selectedPlace: SelectedPlace?

    init(trip: Trip, stay: Stay? = nil) {
        self.trip = trip
        self.stay = stay

        if let stay {
            _name = State(initialValue: stay.name)
            _checkIn = State(initialValue: stay.checkIn)
            _checkOut = State(initialValue: stay.checkOut)
            _confirmationCode = State(initialValue: stay.confirmationCode ?? "")
            _notes = State(initialValue: stay.notes ?? "")
            if let lat = stay.latitude, let lon = stay.longitude {
                _selectedPlace = State(initialValue: SelectedPlace(
                    name: stay.name,
                    address: stay.address,
                    coordinate: .init(latitude: lat, longitude: lon),
                    timeZoneID: stay.timeZoneID
                ))
            } else {
                _selectedPlace = State(initialValue: nil)
            }
        } else {
            let calendar = Calendar.current
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: .now) ?? .now
            let inDate = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: tomorrow) ?? tomorrow
            let outBase = calendar.date(byAdding: .day, value: 3, to: inDate) ?? inDate
            let outDate = calendar.date(bySettingHour: 11, minute: 0, second: 0, of: outBase) ?? outBase
            _name = State(initialValue: "")
            _checkIn = State(initialValue: inDate)
            _checkOut = State(initialValue: outDate)
            _confirmationCode = State(initialValue: "")
            _notes = State(initialValue: "")
            _selectedPlace = State(initialValue: nil)
        }
    }

    private var isEditing: Bool { stay != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Hotel") {
                    TextField("Nome do hotel", text: $name)
                }
                Section("Estadia") {
                    DatePicker("Check-in", selection: $checkIn)
                    DatePicker("Check-out", selection: $checkOut, in: checkIn...)
                }
                PlacePickerSection(
                    title: "Onde",
                    searchPlaceholder: "Buscar hotel ou endereço",
                    highlightedCategories: [.hotel],
                    selection: $selectedPlace
                )
                Section("Reserva") {
                    TextField("Código (opcional)", text: $confirmationCode)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }
                Section("Anotações") {
                    TextField("Opcional", text: $notes, axis: .vertical)
                        .lineLimit(2...6)
                }
            }
            .navigationTitle(isEditing ? "Editar hospedagem" : "Nova hospedagem")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") { save() }
                        .disabled(!canSave)
                }
            }
            .onChange(of: selectedPlace) { _, newValue in
                if let newValue, name.trimmingCharacters(in: .whitespaces).isEmpty {
                    name = newValue.name
                }
            }
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && checkOut > checkIn
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedCode = confirmationCode.trimmingCharacters(in: .whitespaces)
        let timeZoneID = selectedPlace?.timeZoneID ?? TimeZone.current.identifier
        let address = selectedPlace?.address ?? ""

        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        if let stay {
            stay.name = trimmedName
            stay.address = address
            stay.timeZoneID = timeZoneID
            stay.checkIn = checkIn
            stay.checkOut = checkOut
            stay.confirmationCode = trimmedCode.isEmpty ? nil : trimmedCode
            stay.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
            stay.latitude = selectedPlace?.latitude
            stay.longitude = selectedPlace?.longitude
        } else {
            let newStay = Stay(
                name: trimmedName,
                address: address,
                timeZoneID: timeZoneID,
                checkIn: checkIn,
                checkOut: checkOut
            )
            if !trimmedCode.isEmpty {
                newStay.confirmationCode = trimmedCode
            }
            if !trimmedNotes.isEmpty {
                newStay.notes = trimmedNotes
            }
            newStay.latitude = selectedPlace?.latitude
            newStay.longitude = selectedPlace?.longitude
            newStay.trip = trip
            modelContext.insert(newStay)
        }
        NotificationScheduler.shared.refresh(trip: trip)
        WidgetSnapshotWriter.update(trips: [trip])
        dismiss()
    }
}
