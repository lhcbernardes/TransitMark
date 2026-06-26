//
//  WidgetSnapshot.swift
//  TransitMark
//
//  Shared between app target and TransitMarkWidget target.
//  Marque "Target Membership" pros dois alvos no Xcode.
//

import Foundation

struct WidgetSnapshot: Codable, Hashable {
    enum Kind: String, Codable {
        case flight, stay, activity
    }

    let kind: Kind
    let title: String
    let subtitle: String?
    let startDate: Date
    let endDate: Date
    let timeZoneIdentifier: String
    let latitude: Double?
    let longitude: Double?

    static let appGroupID = "group.com.lhcbernardes.TransitMark"
    static let snapshotFilename = "next-event.json"

    static var sharedURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent(snapshotFilename)
    }

    static func load() -> WidgetSnapshot? {
        guard let url = sharedURL,
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder.snapshotDecoder.decode(WidgetSnapshot.self, from: data)
    }

    static func save(_ snapshot: WidgetSnapshot?) {
        guard let url = sharedURL else { return }
        if let snapshot,
           let data = try? JSONEncoder.snapshotEncoder.encode(snapshot) {
            try? data.write(to: url, options: .atomic)
        } else {
            try? FileManager.default.removeItem(at: url)
        }
    }

    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? .current
    }
}

private extension JSONEncoder {
    static var snapshotEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var snapshotDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
