//
//  ActivityEditorView.swift
//  TransitMark
//

import SwiftUI
import SwiftData
import CoreLocation

struct ActivityEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let trip: Trip
    let activity: Activity?

    @State private var title: String
    @State private var startsAt: Date
    @State private var endsAt: Date
    @State private var notes: String
    @State private var selectedPlace: SelectedPlace?

    init(trip: Trip, activity: Activity? = nil) {
        self.trip = trip
        self.activity = activity

        if let activity {
            _title = State(initialValue: activity.title)
            _startsAt = State(initialValue: activity.startsAt)
            _endsAt = State(initialValue: activity.endsAt)
            _notes = State(initialValue: activity.notes ?? "")
            if let lat = activity.latitude, let lon = activity.longitude {
                _selectedPlace = State(initialValue: SelectedPlace(
                    name: activity.locationName ?? activity.title,
                    address: activity.address ?? "",
                    coordinate: .init(latitude: lat, longitude: lon),
                    timeZoneID: activity.timeZoneID
                ))
            } else {
                _selectedPlace = State(initialValue: nil)
            }
        } else {
            let calendar = Calendar.current
            let noonTomorrow = calendar.date(
                bySettingHour: 12, minute: 0, second: 0,
                of: calendar.date(byAdding: .day, value: 1, to: .now) ?? .now
            ) ?? .now
            _title = State(initialValue: "")
            _startsAt = State(initialValue: noonTomorrow)
            _endsAt = State(initialValue: noonTomorrow.addingTimeInterval(3600))
            _notes = State(initialValue: "")
            _selectedPlace = State(initialValue: nil)
        }
    }

    private var isEditing: Bool { activity != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Compromisso") {
                    TextField("Título", text: $title)
                }
                Section("Quando") {
                    DatePicker("Início", selection: $startsAt)
                    DatePicker("Fim", selection: $endsAt, in: startsAt...)
                }
                PlacePickerSection(
                    title: "Onde",
                    searchPlaceholder: "Buscar local ou nome do hotel",
                    selection: $selectedPlace
                )
                conflictSection
                Section("Anotações") {
                    TextField("Opcional", text: $notes, axis: .vertical)
                        .lineLimit(2...6)
                }
            }
            .navigationTitle(isEditing ? "Editar compromisso" : "Novo compromisso")
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
        }
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && endsAt > startsAt
    }

    private var conflicts: [any TripTimelineItem] {
        TripConflictDetector.conflicts(
            with: startsAt..<endsAt,
            in: trip,
            excluding: activity?.id
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
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let timeZoneID = selectedPlace?.timeZoneID ?? TimeZone.current.identifier

        if let activity {
            activity.title = trimmedTitle
            activity.startsAt = startsAt
            activity.endsAt = endsAt
            activity.timeZoneID = timeZoneID
            activity.locationName = selectedPlace?.name
            activity.address = selectedPlace?.address
            activity.latitude = selectedPlace?.latitude
            activity.longitude = selectedPlace?.longitude
            activity.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
        } else {
            let newActivity = Activity(
                title: trimmedTitle,
                timeZoneID: timeZoneID,
                startsAt: startsAt,
                endsAt: endsAt
            )
            newActivity.locationName = selectedPlace?.name
            newActivity.address = selectedPlace?.address
            newActivity.latitude = selectedPlace?.latitude
            newActivity.longitude = selectedPlace?.longitude
            newActivity.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
            newActivity.trip = trip
            modelContext.insert(newActivity)
        }
        NotificationScheduler.shared.refresh(trip: trip)
        WidgetSnapshotWriter.update(trips: [trip])
        dismiss()
    }
}
