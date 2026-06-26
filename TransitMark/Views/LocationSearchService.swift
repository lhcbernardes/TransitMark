//
//  LocationSearchService.swift
//  TransitMark
//

import Foundation
import MapKit

@Observable
@MainActor
final class LocationSearchService: NSObject, MKLocalSearchCompleterDelegate {
    var results: [MKLocalSearchCompletion] = []
    var queryFragment: String = "" {
        didSet { completer.queryFragment = queryFragment }
    }

    private let completer: MKLocalSearchCompleter

    override init() {
        completer = MKLocalSearchCompleter()
        super.init()
        completer.delegate = self
        completer.resultTypes = [.pointOfInterest, .address]
    }

    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let snapshot = completer.results
        Task { @MainActor in
            self.results = snapshot
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            self.results = []
        }
    }

    static func resolve(completion: MKLocalSearchCompletion) async -> MKMapItem? {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        do {
            let response = try await search.start()
            return response.mapItems.first
        } catch {
            return nil
        }
    }
}

struct SelectedPlace: Equatable {
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
    var timeZoneID: String

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init(name: String, address: String, coordinate: CLLocationCoordinate2D, timeZoneID: String) {
        self.name = name
        self.address = address
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.timeZoneID = timeZoneID
    }

    init?(item: MKMapItem) {
        guard let coordinate = item.placemark.location?.coordinate else { return nil }
        let composed = [
            item.placemark.thoroughfare,
            item.placemark.subThoroughfare,
            item.placemark.locality,
            item.placemark.country
        ]
            .compactMap { $0 }
            .joined(separator: ", ")
        self.name = item.name ?? composed
        self.address = composed
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.timeZoneID = item.placemark.timeZone?.identifier ?? TimeZone.current.identifier
    }
}
