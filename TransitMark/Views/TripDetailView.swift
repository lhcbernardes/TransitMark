//
//  TripDetailView.swift
//  TransitMark
//

import SwiftUI
import SwiftData
import MapKit
import CoreLocation

struct TripDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let trip: Trip

    private enum DetailSheet: Identifiable {
        case newActivity
        case editActivity(Activity)
        case newStay
        case editStay(Stay)
        case newFlight
        case editFlight(Flight)
        case connectingFlight(Flight)
        case importBoardingPass

        var id: String {
            switch self {
            case .newActivity:                return "new-activity"
            case .editActivity(let a):        return "edit-activity-\(a.id)"
            case .newStay:                    return "new-stay"
            case .editStay(let s):            return "edit-stay-\(s.id)"
            case .newFlight:                  return "new-flight"
            case .editFlight(let f):          return "edit-flight-\(f.id)"
            case .connectingFlight(let f):    return "connecting-\(f.id)"
            case .importBoardingPass:         return "import-boarding-pass"
            }
        }
    }

    @State private var activeSheet: DetailSheet?
    @State private var exportAlert: ExportAlert?

    private struct ExportAlert: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    private var sortedFlights: [Flight] {
        trip.flights.sorted { $0.scheduledDeparture < $1.scheduledDeparture }
    }

    private var sortedStays: [Stay] {
        trip.stays.sorted { $0.checkIn < $1.checkIn }
    }

    private var activitiesByDay: [(date: Date, timeZone: TimeZone, items: [Activity])] {
        var grouped: [Date: (timeZone: TimeZone, items: [Activity])] = [:]
        for activity in trip.activities {
            var calendar = Calendar.current
            calendar.timeZone = activity.timeZone
            let dayStart = calendar.startOfDay(for: activity.startsAt)
            if grouped[dayStart] == nil {
                grouped[dayStart] = (timeZone: activity.timeZone, items: [activity])
            } else {
                grouped[dayStart]?.items.append(activity)
            }
        }
        return grouped
            .map { entry in
                (date: entry.key,
                 timeZone: entry.value.timeZone,
                 items: entry.value.items.sorted { $0.startsAt < $1.startsAt })
            }
            .sorted { $0.date < $1.date }
    }

    private var chronologicalActivities: [Activity] {
        activitiesByDay.flatMap(\.items)
    }

    private struct DailyActivityEntry: Identifiable {
        let activity: Activity
        let positionInDay: Int
        var id: UUID { activity.id }
    }

    private var dailyMappableActivities: [DailyActivityEntry] {
        var entries: [DailyActivityEntry] = []
        for day in activitiesByDay {
            let withCoords = day.items.filter { $0.coordinate != nil }
            for (index, activity) in withCoords.enumerated() {
                entries.append(DailyActivityEntry(activity: activity, positionInDay: index + 1))
            }
        }
        return entries
    }

    private var dailyPolylines: [(id: Int, coordinates: [CLLocationCoordinate2D])] {
        activitiesByDay.enumerated().compactMap { dayIndex, day in
            let coords = day.items.compactMap { $0.coordinate }
            guard coords.count >= 2 else { return nil }
            return (id: dayIndex, coordinates: coords)
        }
    }

    private var mappableStays: [Stay] {
        sortedStays.filter { $0.coordinate != nil }
    }

    private var hasMappablePoints: Bool {
        !mappableStays.isEmpty || !dailyMappableActivities.isEmpty
    }

    private var hasAnyContent: Bool {
        !trip.activities.isEmpty || !trip.stays.isEmpty || !trip.flights.isEmpty
    }

    var body: some View {
        List {
            if !hasAnyContent {
                Section {
                    ContentUnavailableView(
                        "Sem compromissos",
                        systemImage: "calendar.badge.plus",
                        description: Text("Adicione voos, hospedagens e o que você vai fazer em cada dia.")
                    )
                    .listRowBackground(Color.clear)
                }
            }

            if nextUpcomingItem(after: .now) != nil {
                Section {
                    TimelineView(.periodic(from: .now, by: 60)) { ctx in
                        if let next = nextUpcomingItem(after: ctx.date) {
                            NextUpItemCard(item: next, now: ctx.date)
                        }
                    }
                }
            }

            if !sortedFlights.isEmpty {
                Section("Voos") {
                    ForEach(sortedFlights) { flight in
                        Button {
                            activeSheet = .editFlight(flight)
                        } label: {
                            FlightRow(flight: flight)
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button {
                                activeSheet = .connectingFlight(flight)
                            } label: {
                                Label("Adicionar conexão", systemImage: "arrow.triangle.branch")
                            }
                        }
                    }
                    .onDelete { offsets in
                        delete(flights: offsets.map { sortedFlights[$0] })
                    }
                }
            }

            if !sortedStays.isEmpty {
                Section("Hospedagem") {
                    ForEach(sortedStays) { stay in
                        Button {
                            activeSheet = .editStay(stay)
                        } label: {
                            StayRow(stay: stay)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            if let coordinate = stay.coordinate {
                                Button {
                                    openInMaps(coordinate: coordinate, name: stay.name)
                                } label: {
                                    Label("Navegar", systemImage: "map.fill")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                    .onDelete { offsets in
                        delete(stays: offsets.map { sortedStays[$0] })
                    }
                }
            }

            ForEach(activitiesByDay, id: \.date) { day in
                Section {
                    ForEach(day.items) { activity in
                        Button {
                            activeSheet = .editActivity(activity)
                        } label: {
                            ActivityRow(activity: activity)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .leading, allowsFullSwipe: false) {
                            if let coordinate = activity.coordinate {
                                Button {
                                    openInMaps(coordinate: coordinate, name: activity.title)
                                } label: {
                                    Label("Navegar", systemImage: "map.fill")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                    .onDelete { offsets in
                        delete(activities: offsets.map { day.items[$0] })
                    }
                } header: {
                    dayHeader(for: day.date, in: day.timeZone)
                }
            }

            if hasMappablePoints {
                tripMapSection
            }
        }
        .navigationTitle(trip.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        activeSheet = .newActivity
                    } label: {
                        Label("Atividade", systemImage: "calendar.badge.plus")
                    }
                    Button {
                        activeSheet = .newStay
                    } label: {
                        Label("Hospedagem", systemImage: "bed.double")
                    }
                    Button {
                        activeSheet = .newFlight
                    } label: {
                        Label("Voo", systemImage: "airplane.departure")
                    }
                    Button {
                        activeSheet = .importBoardingPass
                    } label: {
                        Label("Importar boarding pass", systemImage: "sparkles")
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel(Text("Adicionar"))
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ShareLink(item: itineraryText) {
                        Label("Compartilhar itinerário", systemImage: "square.and.arrow.up")
                    }
                    Button {
                        Task { await exportToCalendar() }
                    } label: {
                        Label("Exportar pro Calendar", systemImage: "calendar.badge.checkmark")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityLabel(Text("Mais"))
            }
        }
        .alert(item: $exportAlert) { alert in
            Alert(
                title: Text(alert.title),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .newActivity:
                ActivityEditorView(trip: trip)
            case .editActivity(let activity):
                ActivityEditorView(trip: trip, activity: activity)
            case .newStay:
                StayEditorView(trip: trip)
            case .editStay(let stay):
                StayEditorView(trip: trip, stay: stay)
            case .newFlight:
                FlightEditorView(trip: trip)
            case .editFlight(let flight):
                FlightEditorView(trip: trip, flight: flight)
            case .connectingFlight(let previous):
                FlightEditorView(trip: trip, connectingFrom: previous)
            case .importBoardingPass:
                BoardingPassImporterView(trip: trip)
            }
        }
    }

    @ViewBuilder
    private func dayHeader(for date: Date, in timeZone: TimeZone) -> some View {
        HStack(spacing: 8) {
            Text(Self.formattedDay(date, in: timeZone))
            if isToday(date, in: timeZone) {
                Text("HOJE")
                    .font(.system(.caption2, design: .rounded, weight: .bold))
                    .tracking(0.6)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Color.accentColor, in: Capsule())
                    .foregroundStyle(.white)
            }
        }
    }

    private func isToday(_ date: Date, in timeZone: TimeZone) -> Bool {
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        return calendar.isDateInToday(date)
    }

    private var tripMapSection: some View {
        Section("Mapa da viagem") {
            Map {
                ForEach(dailyPolylines, id: \.id) { entry in
                    MapPolyline(coordinates: entry.coordinates)
                        .stroke(
                            .blue.opacity(0.55),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round, dash: [6, 6])
                        )
                }
                ForEach(mappableStays) { stay in
                    if let coordinate = stay.coordinate {
                        Marker(stay.name, systemImage: "bed.double.fill", coordinate: coordinate)
                            .tint(.red)
                    }
                }
                ForEach(dailyMappableActivities) { entry in
                    if let coordinate = entry.activity.coordinate {
                        Marker(
                            entry.activity.title,
                            monogram: Text("\(entry.positionInDay)"),
                            coordinate: coordinate
                        )
                        .tint(.blue)
                    }
                }
            }
            .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
            .frame(height: 300)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
        }
    }

    private func nextUpcomingItem(after now: Date) -> (any TripTimelineItem)? {
        trip.timelineItems.first { $0.startDate > now }
    }

    private func exportToCalendar() async {
        do {
            let count = try await CalendarExporter.export(trip: trip)
            exportAlert = ExportAlert(
                title: String(localized: "Exportado"),
                message: String(localized: "\(count) eventos foram adicionados ao Calendar.")
            )
        } catch CalendarExportError.permissionDenied {
            exportAlert = ExportAlert(
                title: String(localized: "Sem acesso ao Calendar"),
                message: String(localized: "Permita o acesso em Ajustes → Privacidade → Calendar.")
            )
        } catch {
            exportAlert = ExportAlert(
                title: String(localized: "Falha ao exportar"),
                message: error.localizedDescription
            )
        }
    }

    private var itineraryText: String {
        var lines: [String] = ["🗺 \(trip.name)", ""]
        for flight in sortedFlights {
            var dep = Date.FormatStyle(date: .abbreviated, time: .shortened)
            dep.timeZone = flight.originTimeZone
            var arr = Date.FormatStyle(date: .abbreviated, time: .shortened)
            arr.timeZone = flight.destinationTimeZone
            lines.append("✈ \(flight.displayCode)")
            lines.append("  \(flight.originAirportCode) → \(flight.destinationAirportCode)")
            lines.append("  \(flight.scheduledDeparture.formatted(dep)) → \(flight.scheduledArrival.formatted(arr))")
            if let seat = flight.seat { lines.append("  Assento: \(seat)") }
            if let gate = flight.gate { lines.append("  Portão: \(gate)") }
            lines.append("")
        }
        for stay in sortedStays {
            var style = Date.FormatStyle(date: .abbreviated, time: .omitted)
            style.timeZone = stay.timeZone
            lines.append("🏨 \(stay.name)")
            lines.append("  Check-in: \(stay.checkIn.formatted(style))")
            lines.append("  Check-out: \(stay.checkOut.formatted(style))")
            if !stay.address.isEmpty { lines.append("  \(stay.address)") }
            if let code = stay.confirmationCode { lines.append("  Reserva: \(code)") }
            lines.append("")
        }
        for day in activitiesByDay {
            var dateStyle = Date.FormatStyle(date: .complete, time: .omitted)
            dateStyle.timeZone = day.timeZone
            lines.append("📅 \(day.date.formatted(dateStyle))")
            for activity in day.items {
                var t = Date.FormatStyle.dateTime.hour().minute()
                t.timeZone = activity.timeZone
                lines.append("  \(activity.startsAt.formatted(t))–\(activity.endsAt.formatted(t)) · \(activity.title)")
                if let loc = activity.locationName { lines.append("    \(loc)") }
            }
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }

    private func openInMaps(coordinate: CLLocationCoordinate2D, name: String) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let item = MKMapItem(location: location, address: nil)
        item.name = name
        item.openInMaps()
    }

    private func delete(activities: [Activity]) {
        for activity in activities {
            modelContext.delete(activity)
        }
        NotificationScheduler.shared.refresh(trip: trip)
        WidgetSnapshotWriter.update(trips: [trip])
    }

    private func delete(stays: [Stay]) {
        for stay in stays {
            modelContext.delete(stay)
        }
        NotificationScheduler.shared.refresh(trip: trip)
        WidgetSnapshotWriter.update(trips: [trip])
    }

    private func delete(flights: [Flight]) {
        for flight in flights {
            modelContext.delete(flight)
        }
        NotificationScheduler.shared.refresh(trip: trip)
        WidgetSnapshotWriter.update(trips: [trip])
    }

    private static func formattedDay(_ date: Date, in timeZone: TimeZone) -> String {
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        var style = Date.FormatStyle(date: .complete, time: .omitted)
        style.calendar = calendar
        style.timeZone = timeZone
        return date.formatted(style).capitalized
    }
}

private struct NextUpItemCard: View {
    let item: any TripTimelineItem
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.right.circle.fill")
                Text("PRÓXIMO")
                    .tracking(0.6)
            }
            .font(.system(.caption, design: .rounded, weight: .semibold))
            .foregroundStyle(.tint)

            Text(title)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .lineLimit(2)

            HStack(spacing: 6) {
                Text(itemTime)
                    .foregroundStyle(.secondary)
                Text("·")
                    .foregroundStyle(.tertiary)
                Text(countdown)
                    .foregroundStyle(.tint)
                    .fontWeight(.semibold)
            }
            .font(.system(.caption, design: .rounded))
            .monospacedDigit()
        }
        .padding(.vertical, 4)
    }

    private var title: String {
        if let stay = item as? Stay { return String(localized: "Check-in: \(stay.name)") }
        if let flight = item as? Flight { return String(localized: "Voo \(flight.displayCode)") }
        return item.displayTitle
    }

    private var itemTime: String {
        var style = Date.FormatStyle.dateTime.weekday().hour().minute()
        style.timeZone = item.timeZone
        return item.startDate.formatted(style)
    }

    private var countdown: String {
        let seconds = Int(item.startDate.timeIntervalSince(now))
        if seconds <= 0 { return String(localized: "agora") }
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let days = hours / 24
        if days >= 1 {
            if days == 1 { return String(localized: "em 1 dia") }
            return String(localized: "em \(days) dias")
        }
        if hours > 0 {
            return String(localized: "em \(hours)h \(minutes)min")
        }
        if minutes > 0 {
            return String(localized: "em \(minutes)min")
        }
        return String(localized: "em instantes")
    }
}

struct ActivityRow: View {
    let activity: Activity

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(timeRange)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(.tint)
                    .monospacedDigit()
            }
            .frame(width: 92, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.system(.body, design: .rounded, weight: .medium))
                if let place = activity.locationName ?? activity.address {
                    Text(place)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var timeRange: String {
        var style = Date.FormatStyle.dateTime.hour().minute()
        style.timeZone = activity.timeZone
        return "\(activity.startsAt.formatted(style))–\(activity.endsAt.formatted(style))"
    }
}

struct StayRow: View {
    let stay: Stay

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "bed.double.fill")
                .foregroundStyle(.tint)
                .font(.title3)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(stay.name)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                Text(dateRange)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                if !stay.address.isEmpty {
                    Text(stay.address)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var dateRange: String {
        var style = Date.FormatStyle(date: .abbreviated, time: .omitted)
        style.timeZone = stay.timeZone
        return "\(stay.checkIn.formatted(style)) → \(stay.checkOut.formatted(style))"
    }
}

struct FlightRow: View {
    let flight: Flight

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "airplane.departure")
                .foregroundStyle(.tint)
                .font(.title3)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(flight.displayCode)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                HStack(spacing: 6) {
                    Text(flight.originAirportCode)
                    Image(systemName: "arrow.right")
                        .font(.caption2)
                    Text(flight.destinationAirportCode)
                }
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)
                .monospacedDigit()
                Text(timeRange)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
            }
        }
        .padding(.vertical, 4)
    }

    private var timeRange: String {
        var depStyle = Date.FormatStyle(date: .abbreviated, time: .shortened)
        depStyle.timeZone = flight.originTimeZone
        var arrStyle = Date.FormatStyle(date: .abbreviated, time: .shortened)
        arrStyle.timeZone = flight.destinationTimeZone
        return "\(flight.scheduledDeparture.formatted(depStyle)) → \(flight.scheduledArrival.formatted(arrStyle))"
    }
}
