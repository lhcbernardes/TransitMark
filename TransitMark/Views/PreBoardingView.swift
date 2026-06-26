//
//  PreBoardingView.swift
//  TransitMark
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct PreBoardingView: View {
    let flight: Flight

    @State private var qrImage: CGImage?

    private var qrPayload: String {
        flight.confirmationCode ?? flight.flightNumber
    }

    var body: some View {
        VStack(spacing: 36) {
            header
            routeView
            keyInfoRow
            Spacer(minLength: 0)
            boardingPassCard
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .maxBrightnessWhilePresented()
        .task(id: qrPayload) {
            let payload = qrPayload
            let image = await Task.detached(priority: .userInitiated) {
                Self.makeQRCode(from: payload)
            }.value
            await MainActor.run { qrImage = image }
        }
    }

    private var header: some View {
        Text(flight.displayCode)
            .font(.system(.callout, design: .rounded, weight: .medium))
            .foregroundStyle(.secondary)
    }

    private var routeView: some View {
        HStack(alignment: .top, spacing: 12) {
            airportColumn(
                code: flight.originAirportCode,
                name: flight.originAirportName,
                time: flight.scheduledDeparture,
                timeZone: flight.originTimeZone,
                alignment: .leading
            )
            Image(systemName: "airplane")
                .font(.title3)
                .foregroundStyle(.secondary)
                .padding(.top, 14)
            airportColumn(
                code: flight.destinationAirportCode,
                name: flight.destinationAirportName,
                time: flight.scheduledArrival,
                timeZone: flight.destinationTimeZone,
                alignment: .trailing
            )
        }
    }

    private func airportColumn(
        code: String,
        name: String,
        time: Date,
        timeZone: TimeZone,
        alignment: HorizontalAlignment
    ) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(code)
                .font(.system(size: 40, weight: .bold, design: .rounded))
            Text(name)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(Self.formattedTime(time, in: timeZone))
                .font(.system(.callout, design: .rounded, weight: .semibold))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .trailing)
    }

    private var keyInfoRow: some View {
        HStack(spacing: 0) {
            infoBlock(label: "Terminal", value: flight.terminal ?? "—")
            infoBlock(label: "Portão", value: flight.gate ?? "—", emphasized: true)
            infoBlock(label: "Assento", value: flight.seat ?? "—")
        }
    }

    private func infoBlock(label: String, value: String, emphasized: Bool = false) -> some View {
        VStack(spacing: 6) {
            Text(label.uppercased())
                .font(.system(.caption2, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)
                .tracking(0.8)
            Text(value)
                .font(.system(size: emphasized ? 42 : 28, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
    }

    private var boardingPassCard: some View {
        VStack(spacing: 14) {
            qrCodeView
                .frame(width: 220, height: 220)
            if let name = flight.passengerName {
                Text(name)
                    .font(.system(.footnote, design: .rounded, weight: .medium))
                    .tracking(0.6)
                    .foregroundStyle(.secondary)
            }
            if flight.confirmationCode == nil {
                Label("Adicione o código de reserva para o QR válido", systemImage: "exclamationmark.triangle.fill")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.1), radius: 18, y: 4)
        )
        .environment(\.colorScheme, .light)
    }

    @ViewBuilder
    private var qrCodeView: some View {
        if let qrImage {
            Image(decorative: qrImage, scale: 1)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .accessibilityLabel(Text("Cartão de embarque"))
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(.gray.opacity(0.15))
        }
    }

    private static func formattedTime(_ date: Date, in timeZone: TimeZone) -> String {
        var style = Date.FormatStyle.dateTime.hour().minute()
        style.timeZone = timeZone
        return date.formatted(style)
    }

    private static func makeQRCode(from string: String) -> CGImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        return context.createCGImage(scaled, from: scaled.extent)
    }
}

#Preview {
    PreBoardingView(flight: SampleData.preBoardingFlight())
}
