//
//  TransitMarkWidget.swift
//  TransitMarkWidget
//

import WidgetKit
import SwiftUI

struct NextEventEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
}

struct NextEventProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextEventEntry {
        NextEventEntry(date: .now, snapshot: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (NextEventEntry) -> Void) {
        completion(NextEventEntry(date: .now, snapshot: WidgetSnapshot.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextEventEntry>) -> Void) {
        let snapshot = WidgetSnapshot.load()
        let now = Date()
        let offsets: [TimeInterval] = [0, 5 * 60, 15 * 60, 30 * 60, 3600, 2 * 3600]
        let entries = offsets.map {
            NextEventEntry(date: now.addingTimeInterval($0), snapshot: snapshot)
        }
        let refreshAfter = snapshot?.startDate ?? now.addingTimeInterval(2 * 3600)
        completion(Timeline(entries: entries, policy: .after(refreshAfter)))
    }
}

struct NextEventEntryView: View {
    let entry: NextEventEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let snapshot = entry.snapshot {
            content(for: snapshot)
        } else {
            placeholderContent
        }
    }

    @ViewBuilder
    private func content(for snapshot: WidgetSnapshot) -> some View {
        switch family {
        case .systemSmall: smallLayout(snapshot)
        default: mediumLayout(snapshot)
        }
    }

    private func smallLayout(_ snapshot: WidgetSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon(for: snapshot.kind))
                    .font(.caption)
                Text(label(for: snapshot.kind))
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .tracking(0.6)
            }
            .foregroundStyle(.tint)

            Text(snapshot.title)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .lineLimit(2)

            Spacer()

            Text(snapshot.startDate, style: .relative)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func mediumLayout(_ snapshot: WidgetSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon(for: snapshot.kind))
                Text(label(for: snapshot.kind))
                    .tracking(0.8)
                Spacer()
                Text(snapshot.startDate, style: .relative)
                    .monospacedDigit()
            }
            .font(.system(.caption, design: .rounded, weight: .semibold))
            .foregroundStyle(.tint)

            Text(snapshot.title)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .lineLimit(2)

            if let subtitle = snapshot.subtitle {
                Text(subtitle)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            HStack(alignment: .bottom) {
                Text(formattedTime(snapshot))
                    .font(.system(.caption, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                Spacer()
                if let url = mapsURL(for: snapshot) {
                    Link(destination: url) {
                        Label("Navegar", systemImage: "map.fill")
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.tint.opacity(0.15), in: Capsule())
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private func mapsURL(for snapshot: WidgetSnapshot) -> URL? {
        guard let lat = snapshot.latitude, let lon = snapshot.longitude else { return nil }
        return URL(string: "maps://?daddr=\(lat),\(lon)")
    }

    private var placeholderContent: some View {
        VStack(spacing: 8) {
            Image(systemName: "airplane")
                .font(.title)
                .foregroundStyle(.tint)
            Text("TransitMark")
                .font(.system(.headline, design: .rounded, weight: .bold))
            Text("Sem compromissos")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func icon(for kind: WidgetSnapshot.Kind) -> String {
        switch kind {
        case .flight:   return "airplane.departure"
        case .stay:     return "bed.double.fill"
        case .activity: return "calendar"
        }
    }

    private func label(for kind: WidgetSnapshot.Kind) -> String {
        switch kind {
        case .flight:   return "PRÓXIMO VOO"
        case .stay:     return "CHECK-IN"
        case .activity: return "PRÓXIMO"
        }
    }

    private func formattedTime(_ snapshot: WidgetSnapshot) -> String {
        var style = Date.FormatStyle.dateTime.weekday(.short).hour().minute()
        style.timeZone = snapshot.timeZone
        return snapshot.startDate.formatted(style)
    }
}

struct TransitMarkWidget: Widget {
    let kind: String = "TransitMarkNextEvent"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextEventProvider()) { entry in
            NextEventEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Próximo compromisso")
        .description("O próximo voo, check-in ou atividade da sua viagem.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemMedium) {
    TransitMarkWidget()
} timeline: {
    NextEventEntry(
        date: .now,
        snapshot: WidgetSnapshot(
            kind: .flight,
            title: "JL 8390",
            subtitle: "GRU → HND",
            startDate: .now.addingTimeInterval(3 * 3600),
            endDate: .now.addingTimeInterval(28 * 3600),
            timeZoneIdentifier: "America/Sao_Paulo",
            latitude: -23.435556,
            longitude: -46.473056
        )
    )
    NextEventEntry(date: .now, snapshot: nil)
}
