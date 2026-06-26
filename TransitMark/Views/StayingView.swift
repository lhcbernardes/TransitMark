//
//  StayingView.swift
//  TransitMark
//

import SwiftUI

struct StayingView: View {
    let currentStay: Stay?
    let upcomingItems: [any TripTimelineItem]
    var now: Date = .now

    var body: some View {
        VStack(spacing: 24) {
            if let stay = currentStay {
                stayHeader(stay)
            }
            content
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func stayHeader(_ stay: Stay) -> some View {
        VStack(spacing: 6) {
            Text("HOSPEDADO EM")
                .font(.system(.caption2, design: .rounded, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(.secondary)
            Text(stay.name)
                .font(.system(.title3, design: .rounded, weight: .semibold))
            HStack(spacing: 5) {
                Image(systemName: "clock")
                    .font(.caption2)
                Text(localTime(in: stay.timeZone))
                    .font(.system(.callout, design: .rounded, weight: .medium))
                    .monospacedDigit()
            }
            .foregroundStyle(.secondary)
        }
    }

    private func localTime(in timeZone: TimeZone) -> String {
        var style = Date.FormatStyle.dateTime.hour().minute()
        style.timeZone = timeZone
        return now.formatted(style)
    }

    @ViewBuilder
    private var content: some View {
        if upcomingItems.isEmpty {
            Spacer()
            ContentUnavailableView(
                "Nada mais para hoje",
                systemImage: "moon.stars",
                description: Text("Aproveite o resto do dia.")
            )
            Spacer()
        } else {
            TabView {
                ForEach(upcomingItems, id: \.id) { item in
                    TimelineCard(item: item)
                        .padding(.horizontal, 4)
                        .padding(.bottom, 32)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
    }
}

private struct TimelineCard: View {
    let item: any TripTimelineItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            timeLabel
            titleLabel
            if let subtitle {
                Text(subtitle)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer()
            iconBadge
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.background.secondary)
        )
    }

    private var timeLabel: some View {
        Text(timeRange)
            .font(.system(.callout, design: .rounded, weight: .semibold))
            .foregroundStyle(.tint)
            .monospacedDigit()
    }

    private var titleLabel: some View {
        Text(title)
            .font(.system(.title2, design: .rounded, weight: .bold))
            .lineLimit(2)
    }

    private var title: String { item.displayTitle }

    private var subtitle: String? { item.displaySubtitle }

    private var iconBadge: some View {
        Image(systemName: item.displaySymbol)
            .font(.system(size: 36, weight: .semibold))
            .foregroundStyle(.tint)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private var timeRange: String {
        var style = Date.FormatStyle.dateTime.hour().minute()
        style.timeZone = item.timeZone
        return "\(item.startDate.formatted(style)) – \(item.endDate.formatted(style))"
    }
}

#if DEBUG
#Preview("Com agenda") {
    StayingView(
        currentStay: SampleData.tokyoStay(),
        upcomingItems: SampleData.tokyoDayItems()
    )
}

#Preview("Sem agenda") {
    StayingView(
        currentStay: SampleData.tokyoStay(),
        upcomingItems: []
    )
}
#endif
