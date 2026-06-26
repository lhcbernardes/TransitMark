//
//  Trip+Archive.swift
//  TransitMark
//

import Foundation

extension Trip {
    static let archiveThresholdDays: Int = 7

    var isArchived: Bool {
        if manuallyArchived { return true }
        guard let endDate else { return false }
        let cutoff = Calendar.current.date(
            byAdding: .day,
            value: -Self.archiveThresholdDays,
            to: .now
        ) ?? .now
        return endDate < cutoff
    }
}
