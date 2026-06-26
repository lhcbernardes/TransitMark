//
//  InFlightView.swift
//  TransitMark
//

import SwiftUI
import UIKit
import MapKit
import CoreLocation

struct InFlightView: View {
    let flight: Flight
    let destinationStay: Stay?
    var now: Date = .now

    @State private var didCopy = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 28) {
                arrivalHeader
                progressBlock
                timezonesBlock
                if let stay = destinationStay {
                    stayBlock(stay)
                } else {
                    Text("Sem hospedagem registrada para a chegada.")
                        .font(.system(.callout, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                if let stay = destinationStay {
                    actionButtons(for: stay)
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 40)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Computed properties

    private var flightProgress: Double {
        let total = flight.scheduledArrival.timeIntervalSince(flight.scheduledDeparture)
        guard total > 0 else { return 1 }
        let elapsed = now.timeIntervalSince(flight.scheduledDeparture)
        return max(0, min(1, elapsed / total))
    }

    private var timeRemaining: String {
        let seconds = max(0, Int(flight.scheduledArrival.timeIntervalSince(now)))
        if seconds < 300 { return String(localized: "Pousando em breve") }
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 { return String(localized: "Chegada em \(hours)h \(minutes)min") }
        return String(localized: "Chegada em \(minutes)min")
    }

    // MARK: - Views

    private var arrivalHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("CHEGADA")
                .font(.system(.caption2, design: .rounded, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(.secondary)
            Text(flight.destinationAirportName)
                .font(.system(.title2, design: .rounded, weight: .semibold))
                .foregroundStyle(.white)
            Text(Self.formattedTime(flight.scheduledArrival, in: flight.destinationTimeZone))
                .monospacedDigit()
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }

    private var progressBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.18))
                    .frame(height: 4)
                GeometryReader { geo in
                    Capsule()
                        .fill(.white)
                        .frame(width: geo.size.width * flightProgress, height: 4)
                }
                .frame(height: 4)
            }
            Text(timeRemaining)
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    private var timezonesBlock: some View {
        HStack(spacing: 0) {
            clockColumn(label: flight.originAirportCode, timeZone: flight.originTimeZone)
            Rectangle()
                .fill(.white.opacity(0.2))
                .frame(width: 1, height: 36)
            clockColumn(label: flight.destinationAirportCode, timeZone: flight.destinationTimeZone)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 20)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func clockColumn(label: String, timeZone: TimeZone) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(.caption2, design: .rounded, weight: .semibold))
                .tracking(1.0)
                .foregroundStyle(.secondary)
            Text(currentTime(in: timeZone))
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(.white)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
    }

    private func currentTime(in timeZone: TimeZone) -> String {
        var style = Date.FormatStyle.dateTime.hour().minute()
        style.timeZone = timeZone
        return now.formatted(style)
    }

    private func stayBlock(_ stay: Stay) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(stay.name)
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(.white)
            Text(stay.address)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
            if let code = stay.confirmationCode {
                HStack(spacing: 6) {
                    Text("RESERVA")
                        .font(.system(.caption2, design: .rounded, weight: .semibold))
                        .tracking(1.0)
                        .foregroundStyle(.secondary)
                    Text(code)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold).monospaced())
                        .foregroundStyle(.white)
                }
                .padding(.top, 4)
            }
        }
    }

    private func actionButtons(for stay: Stay) -> some View {
        VStack(spacing: 10) {
            if stay.coordinate != nil {
                Button { openRoute(to: stay) } label: {
                    Label("Como chegar", systemImage: "arrow.triangle.turn.up.right.circle.fill")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .foregroundStyle(.black)
                        .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            Button {
                UIPasteboard.general.string = stay.address
                withAnimation(.spring(duration: 0.25)) { didCopy = true }
                Task {
                    try? await Task.sleep(for: .seconds(1.6))
                    withAnimation(.easeOut(duration: 0.2)) { didCopy = false }
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: didCopy ? "checkmark" : "doc.on.doc")
                    Text(didCopy ? "Endereço copiado" : "Copiar endereço")
                }
                .font(.system(.body, design: .rounded, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .foregroundStyle(.black)
                .background(.white.opacity(stay.coordinate != nil ? 0.15 : 1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .foregroundStyle(stay.coordinate != nil ? .white : .black)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Actions

    private func openRoute(to stay: Stay) {
        guard let stayCoord = stay.coordinate else { return }
        let stayLocation = CLLocation(latitude: stayCoord.latitude, longitude: stayCoord.longitude)
        let stayItem = MKMapItem(location: stayLocation, address: nil)
        stayItem.name = stay.name

        if let airportCoord = flight.destinationCoordinate {
            let airportLocation = CLLocation(latitude: airportCoord.latitude, longitude: airportCoord.longitude)
            let airportItem = MKMapItem(location: airportLocation, address: nil)
            airportItem.name = flight.destinationAirportName
            MKMapItem.openMaps(
                with: [airportItem, stayItem],
                launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
            )
        } else {
            stayItem.openInMaps(launchOptions: [
                MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
            ])
        }
    }

    private static func formattedTime(_ date: Date, in timeZone: TimeZone) -> String {
        var style = Date.FormatStyle.dateTime.hour().minute()
        style.timeZone = timeZone
        return date.formatted(style)
    }
}

#if DEBUG
#Preview {
    InFlightView(
        flight: SampleData.preBoardingFlight(),
        destinationStay: SampleData.tokyoStay()
    )
}
#endif
