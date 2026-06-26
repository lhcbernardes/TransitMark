//
//  LandingView.swift
//  TransitMark
//

import SwiftUI
import MapKit
import CoreLocation

struct LandingView: View {
    let flight: Flight
    let destinationStay: Stay?

    var body: some View {
        VStack(spacing: 24) {
            header
            if let stay = destinationStay {
                stayMap(stay)
                stayDetails(stay)
                openInMapsButton(stay)
            } else {
                Spacer()
                ContentUnavailableView(
                    "Sem destino na chegada",
                    systemImage: "mappin.slash",
                    description: Text("Nenhuma hospedagem registrada para esta chegada.")
                )
                Spacer()
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("BEM-VINDO A")
                .font(.system(.caption2, design: .rounded, weight: .semibold))
                .tracking(1.2)
                .foregroundStyle(.secondary)
            Text(flight.destinationAirportName)
                .font(.system(.title2, design: .rounded, weight: .semibold))
        }
    }

    @ViewBuilder
    private func stayMap(_ stay: Stay) -> some View {
        if let coordinate = stay.coordinate {
            Map(initialPosition: .region(.init(
                center: coordinate,
                latitudinalMeters: 1200,
                longitudinalMeters: 1200
            ))) {
                Marker(stay.name, coordinate: coordinate)
                    .tint(.red)
            }
            .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
            .frame(height: 220)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.gray.opacity(0.15))
                .frame(height: 220)
                .overlay {
                    Image(systemName: "map")
                        .foregroundStyle(.secondary)
                }
        }
    }

    private func stayDetails(_ stay: Stay) -> some View {
        VStack(spacing: 6) {
            Text(stay.name)
                .font(.system(.title3, design: .rounded, weight: .semibold))
            Text(stay.address)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            HStack(spacing: 6) {
                Image(systemName: "key.horizontal")
                    .foregroundStyle(.secondary)
                Text("Check-in a partir de \(Self.formattedTime(stay.checkIn, in: stay.timeZone))")
                    .font(.system(.callout, design: .rounded, weight: .medium))
            }
            .padding(.top, 8)
        }
    }

    private func openInMapsButton(_ stay: Stay) -> some View {
        Button {
            openInMaps(stay)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "arrow.triangle.turn.up.right.circle.fill")
                Text("Abrir no Mapas")
            }
            .font(.system(.body, design: .rounded, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(.white)
            .background(.blue, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func openInMaps(_ stay: Stay) {
        guard let stayCoord = stay.coordinate else { return }
        let stayLocation = CLLocation(latitude: stayCoord.latitude, longitude: stayCoord.longitude)
        let stayAddress = stay.address.isEmpty ? nil : MKAddress(fullAddress: stay.address, shortAddress: nil)
        let stayItem = MKMapItem(location: stayLocation, address: stayAddress)
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
    LandingView(
        flight: SampleData.preBoardingFlight(),
        destinationStay: SampleData.tokyoStay()
    )
}
#endif
