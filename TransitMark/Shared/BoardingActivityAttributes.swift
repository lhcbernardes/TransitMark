//
//  BoardingActivityAttributes.swift
//  TransitMark
//
//  Mirror of the type defined in TransitMarkWidgetLiveActivity.swift (widget target).
//  ActivityKit serializes state via Codable, so both targets can define the same
//  struct independently as long as the layout is identical.
//

import ActivityKit
import Foundation

struct BoardingActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var gate: String?
        var status: String
        var scheduledDeparture: Date
    }

    var airline: String
    var flightCode: String
    var originCode: String
    var destinationCode: String
}
