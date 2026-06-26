//
//  TransitMarkWidgetLiveActivity.swift
//  TransitMarkWidget
//

import ActivityKit
import WidgetKit
import SwiftUI

struct BoardingActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var gate: String?
        var status: String
        var scheduledDeparture: Date
    }

    var airline: String
    var flightCode: String
    var originCode: String
    var destinationCode: String
}

struct TransitMarkWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BoardingActivityAttributes.self) { context in
            lockScreen(context: context)
                .activityBackgroundTint(Color.black)
                .activitySystemActionForegroundColor(Color.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.attributes.originCode)
                            .font(.system(.title2, design: .rounded, weight: .bold))
                        Text("Origem")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(context.attributes.destinationCode)
                            .font(.system(.title2, design: .rounded, weight: .bold))
                        Text("Destino")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.center) {
                    Image(systemName: "airplane")
                        .foregroundStyle(.tint)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        if let gate = context.state.gate {
                            Label("Portão \(gate)", systemImage: "door.left.hand.open")
                                .font(.system(.callout, design: .rounded, weight: .semibold))
                        }
                        Spacer()
                        Text(context.state.scheduledDeparture, style: .relative)
                            .monospacedDigit()
                            .font(.system(.callout, design: .rounded, weight: .semibold))
                    }
                }
            } compactLeading: {
                Image(systemName: "airplane")
                    .foregroundStyle(.tint)
            } compactTrailing: {
                Text(context.state.scheduledDeparture, style: .timer)
                    .monospacedDigit()
                    .frame(maxWidth: 56)
            } minimal: {
                Image(systemName: "airplane")
                    .foregroundStyle(.tint)
            }
            .keylineTint(.orange)
        }
    }

    private func lockScreen(context: ActivityViewContext<BoardingActivityAttributes>) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("\(context.attributes.airline) · \(context.attributes.flightCode)")
                    .font(.system(.callout, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(context.state.status)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(.green)
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text(context.attributes.originCode)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                Spacer()
                Image(systemName: "airplane")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Spacer()
                VStack(alignment: .trailing) {
                    Text(context.attributes.destinationCode)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }

            HStack(spacing: 16) {
                if let gate = context.state.gate {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("PORTÃO")
                            .font(.caption2)
                            .tracking(0.6)
                            .foregroundStyle(.secondary)
                        Text(gate)
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("EMBARQUE")
                        .font(.caption2)
                        .tracking(0.6)
                        .foregroundStyle(.secondary)
                    Text(context.state.scheduledDeparture, style: .timer)
                        .monospacedDigit()
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(20)
    }
}

extension BoardingActivityAttributes {
    fileprivate static var preview: BoardingActivityAttributes {
        BoardingActivityAttributes(
            airline: "JAL",
            flightCode: "JL 8390",
            originCode: "GRU",
            destinationCode: "HND"
        )
    }
}

extension BoardingActivityAttributes.ContentState {
    fileprivate static var onTime: BoardingActivityAttributes.ContentState {
        .init(
            gate: "B24",
            status: "No Prazo",
            scheduledDeparture: .now.addingTimeInterval(45 * 60)
        )
    }
}

#Preview("Lock Screen", as: .content, using: BoardingActivityAttributes.preview) {
    TransitMarkWidgetLiveActivity()
} contentStates: {
    BoardingActivityAttributes.ContentState.onTime
}
