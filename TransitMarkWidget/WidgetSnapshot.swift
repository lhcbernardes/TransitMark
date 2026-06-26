//
//  WidgetSnapshot.swift
//  TransitMarkWidget
//
//  Cópia do arquivo em TransitMark/Shared/ — JSON shape idêntico
//  para descodificar o que o app escreve no App Group container.
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

    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? .current
    }
}

private extension JSONDecoder {
    static var snapshotDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
