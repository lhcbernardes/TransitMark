//
//  TripTimelineItem.swift
//  TransitMark
//

import Foundation
import CoreLocation

protocol TripTimelineItem {
    var id: UUID { get }
    var startDate: Date { get }
    var endDate: Date { get }
    var coordinate: CLLocationCoordinate2D? { get }
    var displayTitle: String { get }
    var displaySubtitle: String? { get }
    var displaySymbol: String { get }
    var timeZone: TimeZone { get }
}
