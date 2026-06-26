//
//  TripsListView.swift
//  TransitMark
//

import SwiftUI
import SwiftData

struct TripsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Trip.createdAt, order: .reverse) private var trips: [Trip]

    var isPresentedAsSheet: Bool = false

    @State private var showingNewTrip = false
    @State private var editingTrip: Trip?
    @State private var showingSettings = false
    @State private var tripToDelete: Trip?

    var body: some View {
        NavigationStack {
            Group {
                if trips.isEmpty {
                    ContentUnavailableView {
                        VStack(spacing: 14) {
                            BrandSymbol(color: .secondary)
                                .frame(width: 88, height: 88)
                            Text("Sem viagens")
                        }
                    } description: {
                        Text("Toque em ")
                        + Text(Image(systemName: "plus"))
                        + Text(" para cadastrar a primeira.")
                    }
                } else {
                    List {
                        if !activeTrips.isEmpty {
                            Section {
                                ForEach(activeTrips) { trip in
                                    tripRowLink(trip)
                                }
                                .onDelete { delete(activeTrips, at: $0) }
                            }
                        }
                        if !archivedTrips.isEmpty {
                            Section("Arquivadas") {
                                ForEach(archivedTrips) { trip in
                                    tripRowLink(trip)
                                }
                                .onDelete { delete(archivedTrips, at: $0) }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Viagens")
            .navigationDestination(for: Trip.self) { trip in
                TripDetailView(trip: trip)
            }
            .toolbar {
                if isPresentedAsSheet {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Fechar") { dismiss() }
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel(Text("Ajustes"))
                    Button {
                        showingNewTrip = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel(Text("Nova viagem"))
                }
            }
            .sheet(isPresented: $showingNewTrip) {
                TripEditorView()
            }
            .sheet(item: $editingTrip) { trip in
                TripEditorView(trip: trip)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .alert(
                "Apagar viagem?",
                isPresented: Binding(get: { tripToDelete != nil }, set: { if !$0 { tripToDelete = nil } })
            ) {
                Button("Apagar", role: .destructive) {
                    if let trip = tripToDelete { confirmDelete(trip) }
                }
                Button("Cancelar", role: .cancel) {}
            } message: {
                if let trip = tripToDelete {
                    Text("\"\(trip.name)\" e todos os seus dados serão apagados permanentemente.")
                }
            }
        }
    }

    private var activeTrips: [Trip] {
        trips.filter { !$0.isArchived }
    }

    private var archivedTrips: [Trip] {
        trips.filter { $0.isArchived }
    }

    @ViewBuilder
    private func tripRowLink(_ trip: Trip) -> some View {
        NavigationLink(value: trip) {
            TripRow(trip: trip)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            if trip.isArchived && trip.manuallyArchived {
                Button {
                    trip.manuallyArchived = false
                    WidgetSnapshotWriter.update(trips: trips)
                } label: {
                    Label("Desarquivar", systemImage: "arrow.uturn.up")
                }
                .tint(.blue)
            } else if !trip.isArchived {
                Button {
                    trip.manuallyArchived = true
                    WidgetSnapshotWriter.update(trips: trips)
                } label: {
                    Label("Arquivar", systemImage: "archivebox")
                }
                .tint(.orange)
            }
        }
        .contextMenu {
            if !trip.isArchived {
                Button {
                    trip.manuallyArchived = true
                    WidgetSnapshotWriter.update(trips: trips)
                } label: {
                    Label("Arquivar", systemImage: "archivebox")
                }
            } else if trip.manuallyArchived {
                Button {
                    trip.manuallyArchived = false
                    WidgetSnapshotWriter.update(trips: trips)
                } label: {
                    Label("Desarquivar", systemImage: "arrow.uturn.up")
                }
            }
            Button {
                editingTrip = trip
            } label: {
                Label("Editar nome", systemImage: "pencil")
            }
            Button(role: .destructive) {
                tripToDelete = trip
            } label: {
                Label("Apagar", systemImage: "trash")
            }
        }
    }

    private func delete(_ source: [Trip], at offsets: IndexSet) {
        if let index = offsets.first {
            tripToDelete = source[index]
        }
    }

    private func confirmDelete(_ trip: Trip) {
        NotificationScheduler.shared.cancel(trip: trip)
        modelContext.delete(trip)
    }
}

private struct TripRow: View {
    let trip: Trip

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(trip.name)
                .font(.system(.body, design: .rounded, weight: .semibold))
            if let range = dateRange {
                Text(range)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("Sem compromissos")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }

    private var dateRange: String? {
        guard let start = trip.startDate, let end = trip.endDate else { return nil }
        let calendar = Calendar.current
        if calendar.isDate(start, inSameDayAs: end) {
            return start.formatted(date: .abbreviated, time: .omitted)
        }
        return "\(start.formatted(date: .abbreviated, time: .omitted)) – \(end.formatted(date: .abbreviated, time: .omitted))"
    }
}

private struct TripEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let trip: Trip?
    @State private var name: String

    init(trip: Trip? = nil) {
        self.trip = trip
        _name = State(initialValue: trip?.name ?? "")
    }

    private var isEditing: Bool { trip != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Ex: São Paulo → Tóquio", text: $name)
                } header: {
                    Text("Nome da viagem")
                }
            }
            .navigationTitle(isEditing ? "Editar viagem" : "Nova viagem")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let trip {
            trip.name = trimmed
        } else {
            let newTrip = Trip(name: trimmed)
            modelContext.insert(newTrip)
        }
        dismiss()
    }
}

#Preview {
    TripsListView()
        .modelContainer(for: Trip.self, inMemory: true)
}
