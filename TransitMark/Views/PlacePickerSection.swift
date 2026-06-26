//
//  PlacePickerSection.swift
//  TransitMark
//

import SwiftUI
import MapKit
import CoreLocation

struct PlacePickerSection: View {
    let title: LocalizedStringKey
    let searchPlaceholder: LocalizedStringKey
    let highlightedCategories: [MKPointOfInterestCategory]
    @Binding var selection: SelectedPlace?

    @State private var query = ""
    @State private var service = LocationSearchService()
    @State private var camera: MapCameraPosition = .automatic
    @State private var resolveTask: Task<Void, Never>?

    init(
        title: LocalizedStringKey,
        searchPlaceholder: LocalizedStringKey,
        highlightedCategories: [MKPointOfInterestCategory] = [.hotel, .restaurant, .museum],
        selection: Binding<SelectedPlace?>
    ) {
        self.title = title
        self.searchPlaceholder = searchPlaceholder
        self.highlightedCategories = highlightedCategories
        self._selection = selection
    }

    var body: some View {
        Group {
            Section(title) {
                searchField
                if !service.results.isEmpty {
                    ForEach(service.results.prefix(6), id: \.self) { completion in
                        Button {
                            select(completion: completion)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(completion.title)
                                    .font(.system(.body, design: .rounded, weight: .medium))
                                    .foregroundStyle(.primary)
                                if !completion.subtitle.isEmpty {
                                    Text(completion.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                }
                if let place = selection {
                    selectedRow(for: place)
                }
            }
            Section {
                Map(position: $camera) {
                    if let place = selection {
                        Marker(place.name, coordinate: place.coordinate)
                            .tint(.red)
                    }
                }
                .mapStyle(.standard(pointsOfInterest: .including(highlightedCategories)))
                .frame(height: 220)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .overlay(alignment: .bottomTrailing) {
                    if let place = selection {
                        openInMapsButton(for: place)
                            .padding(12)
                    }
                }
            }
        }
        .onChange(of: query) { _, newValue in
            service.queryFragment = newValue
        }
        .onChange(of: selection) { _, newValue in
            updateCamera(for: newValue, animated: true)
        }
        .onAppear {
            updateCamera(for: selection, animated: false)
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField(searchPlaceholder, text: $query)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            if !query.isEmpty {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func selectedRow(for place: SelectedPlace) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "mappin.circle.fill")
                .font(.title3)
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(place.name)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                if !place.address.isEmpty {
                    Text(place.address)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer()
            Button {
                selection = nil
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    private func select(completion: MKLocalSearchCompletion) {
        resolveTask?.cancel()
        resolveTask = Task { @MainActor in
            guard let item = await LocationSearchService.resolve(completion: completion) else { return }
            if Task.isCancelled { return }
            guard let place = SelectedPlace(item: item) else { return }
            selection = place
            query = ""
        }
    }

    private func openInMapsButton(for place: SelectedPlace) -> some View {
        Button {
            let location = CLLocation(latitude: place.latitude, longitude: place.longitude)
            let address = place.address.isEmpty ? nil : MKAddress(fullAddress: place.address, shortAddress: nil)
            let mapItem = MKMapItem(location: location, address: address)
            mapItem.name = place.name
            mapItem.openInMaps()
        } label: {
            Label("Abrir no Mapas", systemImage: "map.fill")
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.regularMaterial, in: Capsule())
                .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
        }
        .buttonStyle(.plain)
    }

    private func updateCamera(for place: SelectedPlace?, animated: Bool) {
        guard let place else {
            camera = .automatic
            return
        }
        let region = MKCoordinateRegion(
            center: place.coordinate,
            latitudinalMeters: 800,
            longitudinalMeters: 800
        )
        if animated {
            withAnimation(.easeInOut(duration: 0.4)) {
                camera = .region(region)
            }
        } else {
            camera = .region(region)
        }
    }
}
